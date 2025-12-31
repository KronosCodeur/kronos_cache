# 🗄️ Kronos Cache

A powerful and intuitive cache system for Flutter with REST-like API, encryption, query builder, and seamless integration with awesome_logger.

Part of **Kronos DEVX Packages** - Tools to improve Flutter Developer Experience.

[![pub package](https://img.shields.io/pub/v/kronos_cache.svg)](https://pub.dev/packages/kronos_cache)
[![GitHub](https://img.shields.io/github/stars/KronosCodeur/kronos_cache.svg?style=social)](https://github.com/KronosCodeur/kronos_cache)

---

## ✨ Features

- 🎯 **REST-like API** - Intuitive `get()`, `post()`, `put()`, `patch()`, `delete()`
- 🔍 **Powerful Query Builder** - Filter, sort, limit with fluent syntax
- 🔒 **Built-in Encryption** - AES-256 encryption for sensitive data
- 📱 **Context Extension** - Access cache via `context.cache`
- 🔄 **Reactive Streams** - Real-time updates with Stream support
- ⚡ **Multiple Adapters** - Hive, SQLite, Memory (extensible)
- 🎨 **Awesome Logger Integration** - All operations logged beautifully
- 📦 **Offline-First** - Perfect for offline applications
- ⏱️ **TTL Support** - Auto-expiration of cached data
- 🎭 **Type-Safe** - Full Dart type safety

---

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  kronos_cache: ^0.1.0
  awesome_logger: ^0.0.1  # For logging
```

---

## 🚀 Quick Start

### 1. Initialize

```dart
import 'package:kronos_cache/kronos_cache.dart';
import 'package:awesome_logger/awesome_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure logger
  AwesomeLogger.configure(AwesomeLoggerConfig.development());
  
  // Initialize cache
  await KronosCache.initialize(
    CacheConfig(
      adapter: HiveAdapter(),
      ttl: Duration(hours: 24),
      encryption: EncryptionConfig(enabled: true, key: 'your-secret-key'),
    ),
  );
  
  runApp(MyApp());
}
```

### 2. Basic Usage

```dart
// Get a collection
final userCache = KronosCache.collection('users');

// Create
await userCache.create('user_123', {
  'name': 'John Doe',
  'email': 'john@example.com',
  'age': 30,
});

// Read
final user = await userCache.get('user_123');

// Update
await userCache.update('user_123', {'age': 31});

// Delete
await userCache.delete('user_123');
```

### 3. REST-like API

```dart
// POST (create)
await userCache.post('/123', userData);

// GET (read)
final data = await userCache.get('123');

// PUT (replace)
await userCache.put('/123', newData);

// PATCH (update)
await userCache.patch('/123', updates);

// DELETE
await userCache.delete('123');
```

### 4. Context Extension

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Access cache via context
    context.cache.set('users', '123', userData);
    final user = await context.cache.get('users', '123');
    
    return Container();
  }
}
```

---

## 🔍 Query Builder

### Simple Queries

```dart
// Get all electronics under $1000
final products = await cache.collection('products')
  .where('category', isEqualTo: 'Electronics')
  .where('price', isLessThan: 1000)
  .where('inStock', isEqualTo: true)
  .orderBy('price')
  .limit(10)
  .get();
```

### Advanced Queries

```dart
// Complex filtering
final results = await cache.collection('users')
  .where('age', isGreaterThan: 18)
  .where('age', isLessThan: 65)
  .where('country', isIn: ['US', 'CA', 'UK'])
  .where('verified', isEqualTo: true)
  .orderBy('createdAt', descending: true)
  .limit(20)
  .get();
```

### Search

```dart
// Full-text search
final results = await cache.collection('posts')
  .search('Flutter development', fields: ['title', 'content'])
  .orderBy('createdAt', descending: true)
  .get();
```

---

## 🔄 Reactive Streams

### Watch Collection

```dart
// Real-time updates
CacheStreamBuilder<List<Map<String, dynamic>>>(
  stream: cache.collection('messages').stream(),
  builder: (context, messages) {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return MessageTile(message: messages[index]);
      },
    );
  },
)
```

### Watch Specific Key

```dart
// Watch a single item
cache.collection('users').watch('current_user').listen((user) {
  print('User updated: ${user?['name']}');
});
```

---

## 📊 Bulk Operations

```dart
// Bulk insert
final items = List.generate(100, (i) => {
  'key': 'item_$i',
  'value': {'name': 'Item $i', 'value': i},
});

await cache.collection('items').bulkCreate(items);

// Bulk delete
await cache.collection('items').bulkDelete(['item_1', 'item_2', 'item_3']);
```

---

## 🔒 Encryption

### Global Encryption

```dart
await KronosCache.initialize(
  CacheConfig(
    adapter: HiveAdapter(),
    encryption: EncryptionConfig(
      enabled: true,
      key: 'your-secret-key',
      algorithm: EncryptionAlgorithm.aes256,
    ),
  ),
);
```

### Per-Collection Encryption

```dart
final sensitiveCache = KronosCache.collection(
  'sensitive_data',
  encryption: EncryptionConfig.secure('another-key'),
);
```

---

## ⏱️ TTL & Expiration

```dart
// Set TTL on create
await cache.create('temp_data', data, ttl: Duration(minutes: 5));

// Default TTL for collection
final tempCache = KronosCache.collection('temp', ttl: Duration(hours: 1));

// Check if expired
final metadata = await cache.getMetadata('temp_data');
```

---

## 🎨 Advanced Features

### Get or Fetch Pattern

```dart
// Cache-first with automatic fetch
final user = await cache.collection('users').getOrFetch(
  'user_123',
  fetcher: () => api.fetchUser('user_123'),
  fromJson: (json) => User.fromJson(json),
  toJson: (user) => user.toJson(),
  ttl: Duration(hours: 1),
);
```

### Metadata

```dart
// Add metadata
await cache.create('item_1', data, metadata: {
  'source': 'api',
  'version': '1.0',
  'needsSync': true,
});

// Get metadata
final metadata = await cache.getMetadata('item_1');

// Update metadata
await cache.updateMetadata('item_1', {'needsSync': false});
```

---

## 📱 Widgets

### CacheBuilder

```dart
CacheBuilder<User>(
  future: cache.collection('users').get('123'),
  builder: (context, user) {
    return UserProfile(user: user);
  },
  loading: (context) => CircularProgressIndicator(),
  error: (context, error) => ErrorWidget(error),
)
```

### CacheStreamBuilder

```dart
CacheStreamBuilder<List<Product>>(
  stream: cache.collection('products').stream(),
  builder: (context, products) {
    return ProductGrid(products: products);
  },
)
```

---

## 🛠️ Adapters

### Hive (Recommended)

```dart
CacheConfig(adapter: HiveAdapter())
```

**Pros**: Fast, efficient, no SQL needed  
**Use for**: Most applications, offline-first apps

### Memory

```dart
CacheConfig(adapter: MemoryAdapter())
```

**Pros**: Lightning fast, perfect for testing  
**Use for**: Tests, temporary cache, development

### Custom Adapter

Implement `CacheAdapter` interface:

```dart
class MyCustomAdapter implements CacheAdapter {
  // Implement all methods
}
```

---

## 📊 Cache Management

### Statistics

```dart
final stats = await KronosCache.getStats();
print('Size: ${stats['sizeFormatted']}');
print('Collections: ${stats['collections']}');
```

### Clear Cache

```dart
// Clear specific collection
await cache.collection('users').clear();

// Clear all cache
await KronosCache.clearAll();
```

---

## 💡 Best Practices

1. **Initialize once** - Call `KronosCache.initialize()` in `main()`
2. **Use collections** - Organize data into logical collections
3. **Set appropriate TTLs** - Expire data that changes frequently
4. **Use encryption** - For sensitive data
5. **Leverage streams** - For real-time UI updates
6. **Bulk operations** - For large datasets
7. **Context extension** - For quick access in widgets

---

## 🎯 Use Cases

### E-Commerce App

```dart
// Products with search and filters
final products = await cache.collection('products')
  .search(query, fields: ['name', 'description'])
  .where('price', isLessThan: maxPrice)
  .where('category', isEqualTo: category)
  .orderBy('price')
  .limit(20)
  .get();
```

### Social Media App

```dart
// Real-time posts feed
CacheStreamBuilder(
  stream: cache.collection('posts')
    .where('userId', isIn: followingIds)
    .orderBy('createdAt', descending: true)
    .stream(),
  builder: (context, posts) => PostsFeed(posts),
)
```

### Messaging App

```dart
// Encrypted messages
final messagesCache = KronosCache.collection(
  'messages',
  encryption: EncryptionConfig.secure(userKey),
);

await messagesCache.create(messageId, encryptedMessage);
```

---

## 🤝 Integration with Awesome Logger

All cache operations are automatically logged:

```
💾 [DATABASE] Creating entry: users/user_123
✅ [SUCCESS] Entry created: users/user_123
🔍 [DEBUG] Getting entry: users/user_123
⏱️ [PERFORMANCE] Timer query_products: 45ms
```

---

## 🔄 Migration from Other Solutions

### From Hive

```dart
// Before
final box = await Hive.openBox('users');
await box.put('123', data);
final user = box.get('123');

// After
final cache = KronosCache.collection('users');
await cache.create('123', data);
final user = await cache.get('123');
```

### From SharedPreferences

```dart
// Before
final prefs = await SharedPreferences.getInstance();
await prefs.setString('key', jsonEncode(data));

// After
await context.cache.set('prefs', 'key', data);
```

---

## 📚 Examples

Check the `/example` folder for complete examples:
- Basic CRUD operations
- Query builder usage
- Stream integration
- Encryption
- Bulk operations

---

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md).

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file.

---

## 👨‍💻 Author

**Arris (KronosCodeur)**

[![GitHub](https://img.shields.io/badge/GitHub-KronosCodeur-black?style=flat&logo=github)](https://github.com/KronosCodeur)

Part of **Kronos DEVX Packages** series  
Created with ❤️ for the Flutter community

---

## 🙏 Support

If you find this package useful:
- ⭐ Star on [GitHub](https://github.com/KronosCodeur/kronos_cache)
- 👍 Like on [pub.dev](https://pub.dev/packages/kronos_cache)
- 🐛 Report issues
- 📢 Share with the community

---

**Next in Kronos DEVX**: More packages coming soon! 🚀