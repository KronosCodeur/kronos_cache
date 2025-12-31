import 'package:flutter/material.dart';
import 'package:kronos_cache/kronos_cache.dart';
import 'package:awesome_logger/awesome_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AwesomeLogger.configure(AwesomeLoggerConfig.development());
  AwesomeLogger.appStart();

  await KronosCache.initialize(
    CacheConfig(
      adapter: HiveAdapter(),
      ttl: Duration(hours: 24),
      maxSize: 100 * 1024 * 1024,
      autoCleanup: true,
      encryption: EncryptionConfig(
        enabled: true,
        key: 'my-secret-key-2024',
      ),
      onInit: () {
        AwesomeLogger.success('🎉 Kronos Cache ready!');
      },
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kronos Cache Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CacheDemoPage(),
    );
  }
}

class CacheDemoPage extends StatefulWidget {
  const CacheDemoPage({super.key});

  @override
  State<CacheDemoPage> createState() => _CacheDemoPageState();
}

class _CacheDemoPageState extends State<CacheDemoPage> {
  final userCache = KronosCache.collection('users');
  final productCache = KronosCache.collection('products');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Kronos Cache Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showCacheStats,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            'Basic Operations',
            [
              ElevatedButton(
                onPressed: _testBasicOperations,
                child: const Text('Test CRUD Operations'),
              ),
              ElevatedButton(
                onPressed: _testContextAccess,
                child: const Text('Test Context Access'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Query Operations',
            [
              ElevatedButton(
                onPressed: _testQueries,
                child: const Text('Test Queries'),
              ),
              ElevatedButton(
                onPressed: _testSearch,
                child: const Text('Test Search'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Stream Operations',
            [
              ElevatedButton(
                onPressed: () => _navigateToStreamDemo(context),
                child: const Text('Stream Demo'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Bulk Operations',
            [
              ElevatedButton(
                onPressed: _testBulkOperations,
                child: const Text('Test Bulk Insert'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Cache Management',
            [
              ElevatedButton(
                onPressed: _clearCache,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Clear All Cache'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Future<void> _testBasicOperations() async {
    AwesomeLogger.section('BASIC OPERATIONS TEST');

    await userCache.create('user_1', {
      'name': 'John Doe',
      'email': 'john@example.com',
      'age': 30,
    });

    final user = await userCache.get('user_1');
    AwesomeLogger.json(user, description: 'Retrieved user');

    await userCache.update('user_1', {'age': 31});

    await userCache.delete('user_1');

    _showMessage('Basic operations completed! Check logs.');
  }

  Future<void> _testContextAccess() async {
    AwesomeLogger.section('CONTEXT ACCESS TEST');

    await context.cache.set('users', 'user_2', {
      'name': 'Jane Smith',
      'email': 'jane@example.com',
    });

    final user = await context.cache.get('users', 'user_2');
    AwesomeLogger.json(user, description: 'User from context');

    _showMessage('Context access test completed!');
  }

  Future<void> _testQueries() async {
    AwesomeLogger.section('QUERY TEST');

    for (int i = 1; i <= 10; i++) {
      await productCache.create('product_$i', {
        'name': 'Product $i',
        'price': i * 10.0,
        'category': i % 2 == 0 ? 'Electronics' : 'Books',
        'inStock': i % 3 != 0,
      });
    }

    final results = await productCache
        .where('category', isEqualTo: 'Electronics')
        .where('price', isLessThan: 70)
        .where('inStock', isEqualTo: true)
        .orderBy('price', descending: true)
        .limit(5)
        .get();

    AwesomeLogger.json(results, description: 'Query results');

    _showMessage('Found ${results.length} products. Check logs.');
  }

  Future<void> _testSearch() async {
    AwesomeLogger.section('SEARCH TEST');

    final results = await productCache
        .search('Product 5', fields: ['name'])
        .get();

    AwesomeLogger.json(results, description: 'Search results');

    _showMessage('Search completed! Check logs.');
  }

  Future<void> _testBulkOperations() async {
    AwesomeLogger.section('BULK OPERATIONS TEST');

    final items = List.generate(100, (i) => {
      'key': 'bulk_$i',
      'value': {
        'id': 'bulk_$i',
        'name': 'Bulk Item $i',
        'value': i,
      }
    });

    await productCache.bulkCreate(items);

    _showMessage('Inserted 100 items! Check logs.');
  }

  void _navigateToStreamDemo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StreamDemoPage()),
    );
  }

  Future<void> _showCacheStats() async {
    final stats = await KronosCache.getStats();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Size: ${stats['sizeFormatted']}'),
            Text('Collections: ${stats['collectionsCount']}'),
            Text('Adapter: ${stats['adapter']}'),
            const SizedBox(height: 8),
            const Text('Collections:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...List<String>.from(stats['collections']).map(
                  (c) => Text('  • $c'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text('This will delete all cached data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await KronosCache.clearAll();
      if (mounted) {
        _showMessage('Cache cleared!');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class StreamDemoPage extends StatelessWidget {
  const StreamDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cache = KronosCache.collection('products');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stream Demo'),
      ),
      body: CacheStreamBuilder<List<Map<String, dynamic>>>(
        stream: cache.stream(),
        builder: (context, products) {
          if (products.isEmpty) {
            return const Center(
              child: Text('No products in cache'),
            );
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                title: Text(product['name'] ?? 'Unknown'),
                subtitle: Text('\$${product['price']}'),
                trailing: Text(product['category'] ?? ''),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final id = DateTime.now().millisecondsSinceEpoch;
          await cache.create('product_$id', {
            'name': 'New Product $id',
            'price': (id % 100) + 10.0,
            'category': 'New',
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}