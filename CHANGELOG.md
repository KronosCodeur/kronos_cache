# CHANGELOG

## [0.0.1] - 2025-12-31

### 🎉 Initial Release

#### ✨ Features
- **Core System**
    - Multi-adapter architecture (Hive, Memory)
    - REST-like API (`get`, `post`, `put`, `patch`, `delete`)
    - Context extension (`context.cache`)
    - Collection-based organization

- **Query Builder**
    - Fluent API for queries
    - Multiple operators (==, !=, <, >, <=, >=, in)
    - Order by support
    - Limit and offset
    - Full-text search

- **Reactive Streams**
    - Collection streams
    - Single key watchers
    - CacheStreamBuilder widget

- **Security**
    - AES-256 encryption
    - Per-collection encryption
    - Key hashing support

- **Bulk Operations**
    - Bulk create/insert
    - Bulk delete
    - Bulk upsert

- **TTL & Expiration**
    - Per-entry TTL
    - Collection-level default TTL
    - Auto-cleanup support

- **Logging**
    - Full awesome_logger integration
    - All operations logged
    - Performance timers

- **Utilities**
    - getOrFetch pattern
    - Metadata support
    - Cache statistics

#### 📦 Adapters
- HiveAdapter - Fast NoSQL storage
- MemoryAdapter - In-memory cache for testing

#### 🎨 Widgets
- CacheBuilder - FutureBuilder for cache
- CacheStreamBuilder - StreamBuilder for cache

#### 📚 Documentation
- Complete README with examples
- API documentation
- Migration guides

---

# 🚀 Getting Started Guide

## Step 1: Create the Package Structure

```bash
# Create main directories
mkdir -p kronos_cache
cd kronos_cache

mkdir -p lib/src/{core,adapters,models,security,extensions,widgets}
mkdir -p example/lib
mkdir -p test

# Create main files
touch lib/kronos_cache.dart
touch lib/src/kronos_cache.dart
touch lib/src/core/{cache_manager.dart,cache_config.dart,cache_collection.dart,cache_query_builder.dart}
touch lib/src/adapters/{cache_adapter.dart,hive_adapter.dart,memory_adapter.dart}
touch lib/src/models/{cache_entry.dart,cache_query.dart,cache_result.dart}
touch lib/src/security/encryption.dart
touch lib/src/extensions/cache_context.dart
touch lib/src/widgets/{cache_builder.dart,cache_stream_builder.dart}

# Create documentation
touch README.md CHANGELOG.md LICENSE
touch example/lib/main.dart
touch test/kronos_cache_test.dart
```

## Step 2: Copy Files

Copiez tous les fichiers que j'ai créés dans leurs emplacements respectifs :

1. `pubspec.yaml` → racine
2. `lib/kronos_cache.dart` → export principal
3. `lib/src/kronos_cache.dart` → classe principale
4. `lib/src/core/cache_config.dart` → configuration
5. `lib/src/adapters/cache_adapter.dart` → interface
6. `lib/src/adapters/hive_adapter.dart` → adapter Hive
7. `lib/src/adapters/memory_adapter.dart` → adapter Memory
8. `lib/src/models/*.dart` → modèles (créer 3 fichiers séparés)
9. `lib/src/core/cache_collection.dart` → collection API
10. `lib/src/core/cache_query_builder.dart` → query builder
11. `lib/src/extensions/cache_context.dart` → context extension
12. `lib/src/widgets/*.dart` → widgets (créer 2 fichiers séparés)
13. `lib/src/security/encryption.dart` → encryption
14. `example/lib/main.dart` → exemple
15. `README.md` → documentation
16. `CHANGELOG.md` → ce fichier

## Step 3: Install Dependencies

```bash
# Dans le dossier racine
flutter pub get

# Dans le dossier example
cd example
flutter pub get
cd ..
```

## Step 4: Generate Code (si nécessaire)

```bash
# Si vous utilisez build_runner pour Hive
flutter pub run build_runner build --delete-conflicting-outputs
```

## Step 5: Run Example

```bash
cd example
flutter run
```

## Step 6: Run Tests

```bash
flutter test
```

## Step 7: Publish (quand prêt)

```bash
# Dry run
flutter pub publish --dry-run

# Publish
flutter pub publish
```

---

## 📝 Notes de Développement

### Architecture

```
kronos_cache/
├── lib/
│   ├── kronos_cache.dart              # Export principal
│   └── src/
│       ├── kronos_cache.dart          # Classe KronosCache
│       ├── core/
│       │   ├── cache_config.dart      # Configuration
│       │   ├── cache_collection.dart  # Collection API
│       │   └── cache_query_builder.dart # Query builder
│       ├── adapters/
│       │   ├── cache_adapter.dart     # Interface
│       │   ├── hive_adapter.dart      # Hive impl
│       │   └── memory_adapter.dart    # Memory impl
│       ├── models/
│       │   ├── cache_entry.dart       # Entry model
│       │   ├── cache_query.dart       # Query model
│       │   └── cache_result.dart      # Result model
│       ├── security/
│       │   └── encryption.dart        # Encryption utils
│       ├── extensions/
│       │   └── cache_context.dart     # BuildContext extension
│       └── widgets/
│           ├── cache_builder.dart     # FutureBuilder widget
│           └── cache_stream_builder.dart # StreamBuilder widget
```

### Prochaines Étapes (v0.2.0)

- [ ] SQLite adapter
- [ ] Synchronisation offline-first
- [ ] Relations entre collections
- [ ] Migration system
- [ ] Compression support
- [ ] Analytics/metrics
- [ ] Web support optimizations

### Tests à Ajouter

```dart
// test/kronos_cache_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kronos_cache/kronos_cache.dart';

void main() {
  group('KronosCache', () {
    setUp(() async {
      await KronosCache.initialize(
        CacheConfig(adapter: MemoryAdapter()),
      );
    });

    test('should initialize', () {
      expect(KronosCache.isInitialized, true);
    });

    test('should create and retrieve data', () async {
      final cache = KronosCache.collection('test');
      await cache.create('key1', {'name': 'test'});
      
      final result = await cache.get('key1');
      expect(result, isNotNull);
      expect(result!['name'], 'test');
    });

    // Plus de tests...
  });
}
```

---

## 🐛 Debugging Tips

1. **Logs ne s'affichent pas ?**
    - Vérifiez que awesome_logger est configuré
    - Utilisez `AwesomeLogger.configure(AwesomeLoggerConfig.development())`

2. **Hive initialization error ?**
    - Assurez-vous d'appeler `WidgetsFlutterBinding.ensureInitialized()`
    - Vérifiez les permissions d'écriture

3. **Encryption errors ?**
    - Vérifiez que la clé est bien définie
    - La clé doit être cohérente entre les sessions

4. **Queries ne retournent rien ?**
    - Vérifiez les types de données (String vs int)
    - Utilisez `.getAll()` pour voir toutes les données
    - Activez le debug logging

---

## 💡 Contribution Guidelines

1. Fork le repo
2. Créez une branche (`feature/ma-fonctionnalite`)
3. Committez vos changements
4. Push vers la branche
5. Ouvrez une Pull Request

### Code Style

- Utilisez `dart format`
- Suivez les conventions Dart/Flutter
- Ajoutez des tests pour les nouvelles fonctionnalités
- Documentez les APIs publiques
- Utilisez awesome_logger pour les logs

---

## 📞 Support

- 🐛 Issues: [GitHub Issues](https://github.com/KronosCodeur/kronos_cache/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/KronosCodeur/kronos_cache/discussions)
- 📧 Email: [codeurk@gmail.com]

---

**Happy Caching! 🚀**