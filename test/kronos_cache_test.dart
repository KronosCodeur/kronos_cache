import 'package:flutter_test/flutter_test.dart';
import 'package:kronos_cache/kronos_cache.dart';

void main() {
  group('KronosCache', () {
    setUp(() async {
      if (KronosCache.isInitialized) {
        await KronosCache.dispose();
      }
    });

    test('initializes correctly', () async {
      await KronosCache.initialize(
        CacheConfig(
          adapter: MemoryAdapter(),
          ttl: const Duration(hours: 1),
        ),
      );
      expect(KronosCache.isInitialized, isTrue);
      expect(KronosCache.config.ttl, const Duration(hours: 1));
    });

    test('throws StateError if not initialized before use', () {
      expect(() => KronosCache.collection('test'), throwsStateError);
      expect(() => KronosCache.config, throwsStateError);
      expect(() => KronosCache.clearAll(), throwsStateError);
      expect(() => KronosCache.getSize(), throwsStateError);
      expect(() => KronosCache.getStats(), throwsStateError);
    });

    test('returns existing collection if already created', () async {
      await KronosCache.initialize(CacheConfig(adapter: MemoryAdapter()));
      final collection1 = KronosCache.collection('users');
      final collection2 = KronosCache.collection('users');
      expect(collection1, equals(collection2));
    });

    test('clearAll clears all data from the adapter', () async {
      await KronosCache.initialize(CacheConfig(adapter: MemoryAdapter()));
      final users = KronosCache.collection('users');
      final products = KronosCache.collection('products');

      await users.create('user1', {'name': 'John'});
      await products.create('prod1', {'name': 'Laptop'});

      expect(await users.get('user1'), isNotNull);
      expect(await products.get('prod1'), isNotNull);

      await KronosCache.clearAll();

      expect(await users.get('user1'), isNull);
      expect(await products.get('prod1'), isNull);
    });

    test('dispose closes the adapter and resets initialization', () async {
      await KronosCache.initialize(CacheConfig(adapter: MemoryAdapter()));
      expect(KronosCache.isInitialized, isTrue);

      await KronosCache.dispose();
      expect(KronosCache.isInitialized, isFalse);
      expect(() => KronosCache.collection('test'), throwsStateError);
    });


    test('getStats returns correct statistics', () async {
      await KronosCache.initialize(CacheConfig(adapter: MemoryAdapter()));
      KronosCache.collection('users');
      KronosCache.collection('products');

      final stats = await KronosCache.getStats();
      expect(stats['collectionsCount'], 2);
      expect(stats['collections'], containsAll(['users', 'products']));
      expect(stats['adapter'], 'MemoryAdapter');
      expect(stats['initialized'], isTrue);
    });

    group('CacheCollection', () {
      late CacheCollection usersCollection;

      setUp(() async {
        await KronosCache.initialize(
          CacheConfig(
            adapter: MemoryAdapter(),
            ttl: const Duration(minutes: 5),
          ),
        );
        usersCollection = KronosCache.collection('users');
      });

      test('create and get entry', () async {
        final data = {'name': 'Alice', 'age': 30};
        await usersCollection.create('user1', data);
        final retrieved = await usersCollection.get('user1');
        expect(retrieved, equals(data));
      });

      test('create with custom TTL', () async {
        final data = {'name': 'Bob'};
        await usersCollection.create('user2', data, ttl: const Duration(seconds: 1));
        final retrieved = await usersCollection.get('user2');
        expect(retrieved, equals(data));
        await Future.delayed(const Duration(seconds: 2));
        expect(await usersCollection.get('user2'), isNull);
      });

      test('update entry', () async {
        await usersCollection.create('user3', {'name': 'Charlie'});
        await usersCollection.update('user3', {'age': 25});
        final updated = await usersCollection.get('user3');
        expect(updated, equals({'name': 'Charlie', 'age': 25}));
      });

      test('delete entry', () async {
        await usersCollection.create('user4', {'name': 'David'});
        expect(await usersCollection.get('user4'), isNotNull);
        await usersCollection.delete('user4');
        expect(await usersCollection.get('user4'), isNull);
      });

      test('exists returns true for existing key', () async {
        await usersCollection.create('user5', {'name': 'Eve'});
        expect(await usersCollection.exists('user5'), isTrue);
      });

      test('exists returns false for non-existing key', () async {
        expect(await usersCollection.exists('non_existent_user'), isFalse);
      });

      test('getAll returns all entries', () async {
        await usersCollection.create('user6', {'name': 'Frank'});
        await usersCollection.create('user7', {'name': 'Grace'});
        final allUsers = await usersCollection.getAll();
        expect(allUsers.length, 2);
        expect(allUsers.any((e) => e['name'] == 'Frank'), isTrue);
        expect(allUsers.any((e) => e['name'] == 'Grace'), isTrue);
      });

      test('stream emits updates', () async {
        final stream = usersCollection.stream();
        expectLater(
          stream,
          emitsInOrder([
            [],
            [
              {'name': 'Heidi'}
            ],
            [
              {'name': 'Heidi', 'age': 40}
            ],
            [],
          ]),
        );

        await Future.delayed(Duration.zero);
        await usersCollection.create('user8', {'name': 'Heidi'});
        await usersCollection.update('user8', {'age': 40});
        await usersCollection.delete('user8');
      });

      test('bulkCreate inserts multiple entries', () async {
        final items = [
          {'key': 'user9', 'value': {'name': 'Ivan'}},
          {'key': 'user10', 'value': {'name': 'Judy'}},
        ];
        await usersCollection.bulkCreate(items);
        expect(await usersCollection.get('user9'), {'name': 'Ivan'});
        expect(await usersCollection.get('user10'), {'name': 'Judy'});
      });

      test('bulkDelete removes multiple entries', () async {
        await usersCollection.create('user11', {'name': 'Karl'});
        await usersCollection.create('user12', {'name': 'Liam'});
        await usersCollection.bulkDelete(['user11', 'user12']);
        expect(await usersCollection.get('user11'), isNull);
        expect(await usersCollection.get('user12'), isNull);
      });

      test('clear collection removes all entries from that collection', () async {
        await usersCollection.create('user13', {'name': 'Mia'});
        final productsCollection = KronosCache.collection('products');
        await productsCollection.create('prodA', {'name': 'Monitor'});

        expect(await usersCollection.get('user13'), isNotNull);
        expect(await productsCollection.get('prodA'), isNotNull);

        await usersCollection.clear();

        expect(await usersCollection.get('user13'), isNull);
        expect(await productsCollection.get('prodA'), isNotNull);
      });

      group('QueryBuilder', () {
        late CacheCollection queryCollection;

        setUp(() async {
          await KronosCache.initialize(CacheConfig(adapter: MemoryAdapter()));
          queryCollection = KronosCache.collection('items');
          await queryCollection.bulkCreate([
            {'key': 'item1', 'value': {'name': 'Apple', 'price': 1.0, 'category': 'Fruit'}},
            {'key': 'item2', 'value': {'name': 'Banana', 'price': 0.5, 'category': 'Fruit'}},
            {'key': 'item3', 'value': {'name': 'Carrot', 'price': 0.8, 'category': 'Vegetable'}},
            {'key': 'item4', 'value': {'name': 'Milk', 'price': 2.5, 'category': 'Dairy'}},
            {'key': 'item5', 'value': {'name': 'Cheese', 'price': 5.0, 'category': 'Dairy'}},
          ]);
        });

        test('where clause with isEqualTo', () async {
          final results = await queryCollection.where('category', isEqualTo: 'Fruit').get();
          expect(results.length, 2);
          expect(results.any((e) => e['name'] == 'Apple'), isTrue);
          expect(results.any((e) => e['name'] == 'Banana'), isTrue);
        });

        test('where clause with isLessThan', () async {
          final results = await queryCollection.where('price', isLessThan: 1.0).get();
          expect(results.length, 2);
          expect(results.any((e) => e['name'] == 'Banana'), isTrue);
          expect(results.any((e) => e['name'] == 'Carrot'), isTrue);
        });

        test('where clause with isGreaterThan', () async {
          final results = await queryCollection.where('price', isGreaterThan: 2.0).get();
          expect(results.length, 2);
          expect(results.any((e) => e['name'] == 'Milk'), isTrue);
          expect(results.any((e) => e['name'] == 'Cheese'), isTrue);
        });

        test('where clause with isLessThanOrEqualTo', () async {
          final results = await queryCollection.where('price', isLessThanOrEqualTo: 0.8).get();
          expect(results.length, 2);
          expect(results.any((e) => e['name'] == 'Banana'), isTrue);
          expect(results.any((e) => e['name'] == 'Carrot'), isTrue);
        });

        test('where clause with isGreaterThanOrEqualTo', () async {
          final results = await queryCollection.where('price', isGreaterThanOrEqualTo: 2.5).get();
          expect(results.length, 2);
          expect(results.any((e) => e['name'] == 'Milk'), isTrue);
          expect(results.any((e) => e['name'] == 'Cheese'), isTrue);
        });

        test('multiple where clauses', () async {
          final results = await queryCollection
              .where('category', isEqualTo: 'Fruit')
              .where('price', isLessThan: 1.0)
              .get();
          expect(results.length, 1);
          expect(results.first['name'], 'Banana');
        });

        test('orderBy ascending', () async {
          final results = await queryCollection.orderBy('price').get();
          expect(results.map((e) => e['name']), ['Banana', 'Carrot', 'Apple', 'Milk', 'Cheese']);
        });

        test('orderBy descending', () async {
          final results = await queryCollection.orderBy('price', descending: true).get();
          expect(results.map((e) => e['name']), ['Cheese', 'Milk', 'Apple', 'Carrot', 'Banana']);
        });

        test('limit clause', () async {
          final results = await queryCollection.limit(2).get();
          expect(results.length, 2);
        });

        test('offset clause', () async {
          final results = await queryCollection.orderBy('price').offset(2).get();
          expect(results.length, 3);
          expect(results.first['name'], 'Apple');
        });

        test('search by field', () async {
          final results = await queryCollection.search('apple', fields: ['name']).get();
          expect(results.length, 1);
          expect(results.first['name'], 'Apple');
        });

        test('search across multiple fields', () async {
          final results = await queryCollection.search('fruit', fields: ['name', 'category']).get();
          expect(results.length, 2);
          expect(results.any((e) => e['name'] == 'Apple'), isTrue);
          expect(results.any((e) => e['name'] == 'Banana'), isTrue);
        });

        test('search case-insensitivity', () async {
          final results = await queryCollection.search('apple', fields: ['name']).get();
          expect(results.length, 1);
          expect(results.first['name'], 'Apple');
        });

        test('complex query combination', () async {
          final results = await queryCollection
              .where('category', isEqualTo: 'Fruit')
              .where('price', isGreaterThan: 0.5)
              .orderBy('name', descending: true)
              .limit(1)
              .get();
          expect(results.length, 1);
          expect(results.first['name'], 'Apple');
        });
      });
    });
  });
}
