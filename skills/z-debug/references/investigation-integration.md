# Integration Investigation Guide

Reference for the `z-debug-investigator-integration` agent. Loaded when spawning the integration investigator.

## Investigation Checklist

### API Contracts
- Compare the API request payload with what the endpoint expects
- Check response shape — does the consumer handle all possible response formats?
- Verify error response handling — are HTTP error codes mapped correctly?
- Check content-type headers and serialization format mismatches

### Event Ordering & Timing
- Map the sequence of operations — is there an ordering assumption that can break?
- Check async operations — are promises/callbacks resolving in expected order?
- Look for race conditions between parallel requests
- Verify debounce/throttle timing in event handlers

### Dependency Versions
- Check package.json/composer.json for version conflicts
- Look for breaking changes in recently updated dependencies
- Verify peer dependency requirements are met
- Check if multiple versions of the same package are installed

### Middleware & Pipeline
- Trace the request through the full middleware pipeline
- Check middleware ordering — is a dependent middleware running before its prerequisite?
- Verify error handling middleware catches the right exceptions
- Look for middleware short-circuiting that skips necessary processing

### Cross-Service Communication
- Check queue/event payloads — do publisher and consumer agree on format?
- Verify service discovery and endpoint configuration
- Look for timeout mismatches between caller and callee
- Check retry logic — are failed operations retried correctly?
