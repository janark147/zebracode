---
argument-hint: "[file-path]"
description: "Optimize documentation for conciseness and clarity by strengthening vague instructions and removing redundancy"
---

# /z-docs-optimise — Optimize Documentation

**Task**: Optimize the documentation file: `$ARGUMENTS`

## Objective

Make documentation more concise and clearer without introducing vagueness or misinterpretation.

**Optimization Goals** (in priority order):
1. **Eliminate vagueness**: Strengthen instructions with explicit criteria and measurable steps
2. **Increase conciseness**: Remove redundancy while preserving all necessary information
3. **Preserve clarity AND meaning**: Never sacrifice understanding or semantic accuracy for brevity

**Critical Constraint**: Instructions (text + examples) should only be updated if the new version retains BOTH the same meaning AND the same clarity as the old version. If optimization reduces clarity or changes meaning, reject the change.

**Idempotent Design**: This command can be run multiple times on the same document:
- **First pass**: Strengthens vague instructions, removes obvious redundancy
- **Second pass**: Further conciseness improvements if instructions are now self-sufficient
- **Subsequent passes**: No changes if already optimized

## Analysis Methodology

For each instruction section in the document:

### Step 1: Evaluate for Vagueness/Ambiguity

**Is the instruction clear WITHOUT the examples?**
- Cover the examples and read only the instruction
- Can it be executed correctly without looking at examples?
- Does it contain subjective terms like "clearly", "properly", "immediately" without definition?
- Are there measurable criteria or explicit steps?

**Decision Tree**:
```
Can instruction be followed correctly without examples?
├─ YES → Instruction is CLEAR → Proceed to Step 2
└─ NO → Instruction is VAGUE → Proceed to Step 3
```

### Step 2: If Clear (Examples Not Needed for Understanding)

**Only proceed here if instruction is unambiguous without examples.**

1. Identify examples following the instruction
2. **Apply Execution Test**: Can Claude execute correctly without this example?
   - If NO (example defines ambiguous term) → **KEEP**
   - If YES → Proceed to step 3
3. Determine if examples serve operational purpose:
   - Defines what "correct" looks like → **KEEP**
   - Shows exact commands with success criteria → **KEEP**
   - Sequential workflows where order matters → **KEEP**
   - Resolves ambiguity in instruction wording → **KEEP**
   - Data structures (JSON formats) → **KEEP**
   - Explains WHY (educational/rationale) → **REMOVE**
   - Only restates already-clear instruction → **REMOVE**

### Step 3: If Vague (Examples Needed for Understanding)

**DO NOT REMOVE EXAMPLES YET — Strengthen instruction first.**

1. Identify the source of vagueness:
   - Subjective terms without definition
   - Missing criteria or measurements
   - Unclear boundaries or edge cases
   - Narrative description instead of explicit steps

2. Strengthen the instruction:
   - Replace subjective terms with explicit criteria
   - Convert narrative to numbered steps
   - Add measurable thresholds or boundaries
   - Define what "success" looks like

3. **KEEP all examples** — They're needed until instruction is strengthened

4. **Mark for next pass**: After strengthening, examples can be re-evaluated in next optimization pass

## Categories of Examples to KEEP (Even with Clear Instructions)

1. **Executable Commands**: Bash scripts, jq commands, git workflows
2. **Data Structures**: JSON formats, configuration schemas, API contracts
3. **Boundary Demonstrations**: Prohibited vs permitted patterns, edge cases
4. **Concept Illustrations**: Examples that show what a vague term means
5. **Templates**: Reusable formats for structured responses
6. **Prevention Examples**: Wrong vs right patterns for frequently violated rules
7. **Pattern Extraction Rules**: Annotations that generalize examples into reusable decision principles

## Categories of Examples to REMOVE

1. **Redundant Clarification**: Examples that restate the instruction in different words
2. **Obvious Applications**: Examples showing trivial applications of clear rules
3. **Duplicate Templates**: Multiple versions of the same template
4. **Verbose Walkthroughs**: Step-by-step narratives when numbered instructions exist

## Execution-Critical Content (NEVER CONDENSE)

### 1. Concrete Examples Defining "Correct"
- Examples showing EXACT correct vs incorrect patterns when instruction uses abstract terms
- **Test**: Does the example define something ambiguous in the instruction?
- **KEEP** when instruction says "delete" but example shows this means "remove entire entry, not mark complete"
- **REMOVE** if instruction already says "remove entire entry" explicitly — example becomes redundant

### 2. Sequential Steps for State Machines
- Numbered workflows where order matters for correctness
- **Test**: Can steps be executed in different order and still work?
- **KEEP** numbered sequence when order is mandatory
- **REMOVE** numbering if steps are independent checks

### 3. Inline Comments That Specify WHAT to Verify
- Comments explaining what output to expect or check
- **KEEP** comments specifying criteria
- **REMOVE** comments explaining WHY

### 4. Disambiguation Examples
- Multiple examples showing boundary between prohibited/permitted
- **KEEP** examples that clarify ambiguous instructions
- **REMOVE** examples that just restate clear instructions

### 5. Pattern Extraction Rules
- Annotations that generalize specific examples into reusable decision principles
- **Test**: If removed, would Claude lose the ability to apply this reasoning to NEW examples not in the document? If YES → KEEP

## Reference-Based Condensing Rules

### NEVER Replace with References
1. Content within sequential workflows (breaks execution flow)
2. Quick-reference lists in methodology sections (serve different purpose)
3. Success criteria at decision points (needed at moment of decision)

### OK to Replace with References
1. Explanatory content that appears in multiple places
2. Content at document boundaries (intro/conclusion)
3. Cross-referencing related but distinct concepts

### Semantic Equivalence Test (before replacing)
1. **Same information**: Referenced section contains EXACT same information
2. **Same context**: Referenced section serves same purpose
3. **Same level of detail**: No precision lost

### Duplication Taxonomy
- **Type 1: Quick-Reference + Detailed** → KEEP BOTH (different use cases)
- **Type 2: Exact Duplication** → CONSOLIDATE (genuine redundancy)
- **Type 3: Pedagogical Repetition** → CONTEXT-DEPENDENT

## The Execution Test (Decision Rule)

Before removing ANY content:

1. **Can Claude execute correctly without this content?** → If NO → KEEP
2. **Does this content explain WHY?** → If YES → REMOVE
3. **Does this content show WHAT "correct" looks like?** → If YES → KEEP
4. **Does this content extract a general decision rule?** → If YES → KEEP

## Conciseness vs Correctness Hierarchy

1. **CORRECTNESS** (highest priority) — Can Claude execute correctly?
2. **EFFICIENCY** (medium) — Faster to scan?
3. **CONCISENESS** (lowest) — Fewer lines?

**Rule**: Never sacrifice correctness for conciseness.

## Conciseness Strategies

1. **Eliminate Redundancy**: Remove repeated info, consolidate overlapping instructions
2. **Tighten Language**: "you MUST execute" → "execute", "in order to" → "to"
3. **Use Structure Over Prose**: Paragraphs → bulleted lists, tables for multi-dimensional info
4. **Preserve Essential Elements**: Commands, data structures, boundary demonstrations, criteria

**Do NOT sacrifice**: Scannability, pattern recognition, explicit criteria, prevention patterns, error conditions.

## Execution Instructions

1. **Read** the document specified: `$ARGUMENTS`
2. **Snapshot** the original (word count, section count) for comparison
3. **Analyze** each section using the methodology above
4. **Optimize** directly:
   - Strengthen vague instructions with explicit criteria
   - Remove redundant content while preserving clarity
   - Apply conciseness strategies where beneficial
5. **Auto-compare** (absorbed from /z-docs-compare):
   - Compare original vs optimized version
   - Verify no important context was lost
   - Report any differences that might affect execution correctness
6. **Report** changes made in your response to the user
7. **Commit** the optimized document with descriptive message

## Quality Standards

Every change must satisfy ALL criteria:
- Meaning preserved
- Executability preserved
- Success criteria intact
- Ambiguity resolved
- Conciseness increased

## Completion Screen

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✓ Docs Optimized — {file}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Before    {word count} words, {section count} sections
  After     {word count} words, {section count} sections
  Reduced   {percent}% smaller
  Compared  original vs optimized ✓ (no context lost)

─────────────────────────────────────────────────────────────────
  ▶ Next    Continue with your current workflow
─────────────────────────────────────────────────────────────────
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
