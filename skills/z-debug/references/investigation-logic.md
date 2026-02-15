# Logic & Edge Case Investigation Guide

Reference for the `z-debug-investigator-logic` agent. Loaded when spawning the logic investigator.

## Investigation Checklist

### Conditionals & Control Flow
- Check all if/else/switch branches — is there a missing case?
- Look for inverted conditions (e.g., `>` instead of `>=`, `&&` instead of `||`)
- Check early returns — do they handle all edge cases?
- Verify loop termination conditions — off-by-one errors

### Null & Undefined Handling
- Trace nullable values through the code path
- Check optional chaining — is it masking a deeper issue?
- Look for `.length` or property access on potentially null values
- Verify default parameter values

### Boundary Values
- Test with: 0, 1, -1, empty string, empty array, max int, min int
- Check pagination boundaries (first page, last page, empty results)
- Verify date boundaries (midnight, DST transitions, timezone edges)
- Check string length limits and truncation behavior

### Type Safety
- Look for implicit type coercion (`==` vs `===`, string + number)
- Check array index types (string vs number keys)
- Verify enum/union type exhaustiveness
- Look for `any` type masking real issues

### Math & Precision
- Check floating-point arithmetic (0.1 + 0.2 !== 0.3)
- Verify integer overflow/underflow scenarios
- Check division by zero guards
- Verify rounding behavior (ceil vs floor vs round)
