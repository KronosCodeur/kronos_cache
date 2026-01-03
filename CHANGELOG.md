# CHANGELOG

## [0.0.1] - 2025-12-31

### Initial Release

#### Features
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


## [0.0.2] - 2025-12-31

### Documentation Changes

## [0.0.3] - 2026-01-03

### Breaking Changes

- CacheCollection: Introduced the isExpired() method to manually verify if a specific entry has exceeded its Time-To-Live (TTL).
