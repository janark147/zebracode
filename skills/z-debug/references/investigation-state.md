# State & Data Investigation Guide

Reference for the `z-debug-investigator-state` agent. Loaded when spawning the state investigator.

## Investigation Checklist

### Data Flow
- Trace the data from source (DB, API, user input) to the point of failure
- Check intermediate transformations — is data mutated unexpectedly?
- Look for implicit type coercion or format changes
- Check serialization/deserialization boundaries (JSON.parse, encode/decode)

### State Management
- Identify all places where the relevant state is read and written
- Check for race conditions in concurrent access patterns
- Look for stale closures capturing outdated state
- Verify state initialization — is there a default that masks the bug?

### Cache & Memoization
- Identify all caching layers (application cache, query cache, CDN, browser)
- Check cache invalidation logic — is stale data being served?
- Look for cache key collisions
- Check TTL values — is cached data outliving its relevance?

### Configuration & Environment
- Check environment variables relevant to the bug
- Look for config differences between environments (dev vs staging vs prod)
- Check feature flags that might alter behavior
- Verify database/service connection configs

### Permissions & Authorization
- Check if the bug occurs only for specific roles/permissions
- Verify middleware/guard ordering — is auth checked before the failing code?
- Look for permission caching issues
