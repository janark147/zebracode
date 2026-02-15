# Test Writing Guide

Loaded during every phase that introduces new or changed behavior. Absorbs the former `/z-tests` command.

## Process

1. **Analyze the phase diff**: What new behavior was added? What existing behavior changed? What edge cases exist?
2. **Read existing test suites**: Examine `tests/`, `spec/`, `__tests__/`, or equivalent for patterns, helpers, fixtures, and conventions. **Your goal is to always use the same patterns throughout the app.**
3. **Read project docs**: Check CLAUDE.md and DOCS.md for test-specific instructions, custom helpers, testing conventions.
4. **Read config**: Use `commands.test_backend` and `commands.test_frontend` from `z-project-config.yml` for run commands.
5. **Use Context7**: Research test framework APIs (PHPUnit, Jest, Vitest, pytest, RSpec, etc.) via Context7 MCP for correct assertion syntax and patterns.

## Coverage Requirements

- **New feature**: Unit/feature tests covering happy path + at least one failure path
- **Bug fix**: Regression test that reproduces the bug + fix verification. Amend existing tests if the fix changes expected behavior.
- **Refactor**: Existing tests should continue passing. Add tests only if coverage was previously missing.
- **API endpoint**: Test request validation (valid + invalid), response structure, auth checks, error responses
- **UI component**: Test rendering, user interactions, edge states (loading, error, empty)

## What NOT to Test

- Framework behavior (e.g., "Laravel validates required fields" — that's Laravel's job)
- Simple getters/setters with no logic
- Third-party library internals
- Database migration execution (trust the ORM)

## Test Quality Rules

- **Follow existing patterns**: Match the project's test style exactly. If tests use factories, use factories. If tests use `describe/it`, use `describe/it`. Consistency is paramount.
- **Meaningful names**: Test names should describe the behavior, not the implementation. `it('returns 403 when user lacks permission')` not `it('checks auth')`.
- **No brittle mocks**: If you must mock, mock interfaces not implementations. Flag any mock that will break if internals change: `⚠ Brittle mock: tightly coupled to {class} internals`.
- **Arrange-Act-Assert**: Structure every test clearly. One assertion per behavior (multiple assertions are fine if testing one behavior from multiple angles).
- **Run affected tests**: After writing tests, run ONLY the affected test file(s). Not the full suite. Report: `{pass} passing, {fail} failing ({time}s)`.
- **If ANY test fails**: STOP and ask user via AskUserQuestion how to proceed. Do not silently skip.

## Evidence Output

After writing tests for a phase, report:
```
Tests: {N} test files, {M} test cases added
Results: {pass} passing, {fail} failing ({time}s)
Coverage: {before}% → {after}% (if tooling supports it)
```
