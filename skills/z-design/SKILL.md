---
argument-hint: "[issue]"
description: "Generate multiple UI/UX design mockups for an issue"
required-predecessor: "z-plan"
required-mcps: ["magic"]
---

# /z-design — UI/UX Mockup Generator

Operates in two modes:
- **Standalone** (this skill, invoked directly) — ad-hoc design exploration
- **Phase handler** (invoked by `/z-work` for `Type: design` phases) — handled via `z-work/references/design-patterns.md`, not this file

## Pre-flight Validation

**Run these checks FIRST.**

1. Verify Magic MCP is available: call `mcp__magic__21st_magic_component_inspiration` with a simple query. If unavailable → display validation-failed screen with install hint.
2. **Predecessor check**: Check that a plan file exists in `.claude/plans/` matching the issue or branch. If no plan file found → display blocked screen and redirect to `/z-plan {issue}`.

### Blocked Screen

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✗ Design Blocked — no plan file found
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Required     Plan file must exist
  Missing      .claude/plans/{issue}*.md

─────────────────────────────────────────────────────────────────
  ▶ Run first  /z-plan {issue}
               Create an implementation plan
─────────────────────────────────────────────────────────────────
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Argument Parsing

- **Issue ID**: First positional argument. If not provided, derive from current branch name.
- Read plan file: `.claude/plans/$ARGUMENTS*` — if no argument, use `.claude/plans/X*` where X = current branch name.

---

## Execution

### Step 1: Scan Existing Codebase

**THIS IS CRITICAL.** Before generating any mockups, THOROUGHLY scan the existing codebase:

- Find ALL existing UI components — buttons, inputs, modals, cards, tables, forms, navbars, sidebars, etc.
- Identify the component library in use (CoreUI, Vuetify, MUI, Shadcn, etc.) and its available components
- Note the CSS framework (Tailwind, Bootstrap, custom SCSS, etc.) and existing utility classes
- Catalog spacing conventions, icon sets, color tokens, typography scale
- Check existing page layouts for structural patterns (grid systems, container widths, responsive breakpoints)
- Identify existing design patterns that MUST be reused — do NOT create custom components when equivalent ones exist

**Reuse is mandatory.** The mockups must look and feel like part of the existing application.

### Step 2: Generate Mockups

Provide at least **5 distinct mockup variations**, each exploring a different approach:

- Different layouts (sidebar vs tabs vs accordion vs wizard, etc.)
- Different interaction patterns (inline editing vs modal, progressive disclosure vs all-at-once, etc.)
- Different visual treatments within the existing design language
- Different component compositions using existing building blocks

For each mockup:
1. Use **Magic MCP** tools:
   - `mcp__magic__21st_magic_component_builder` — generate component code
   - `mcp__magic__21st_magic_component_inspiration` — explore design ideas
   - `mcp__magic__21st_magic_component_refiner` — iterate on a direction
2. Provide as much **live functionality** as possible — working buttons, real layouts, interactive elements
3. Don't be afraid to temporarily modify existing files to show mockups in context
4. Each mockup should have a brief label and description of its approach

### Step 3: Present to User

Use **AskUserQuestion** to present all mockups and let the user choose:
- "Which mockup direction do you prefer? You can combine elements from multiple."
- Allow iteration — if the user wants to explore a direction further, generate variations on that theme
- Keep iterating until the user is satisfied with a direction

### Step 4: Document the Decision

After the user selects a mockup, update the plan file's `## Design Decisions` section:

- Selected mockup name/number and description
- Component inventory: new components to create vs existing ones to reuse
- Layout approach and rationale
- Any deviations from existing design patterns (with justification)

**Append, don't overwrite** — preserve history of design iterations if this skill is invoked multiple times.

### Step 5: Clean Up

- Remove any temporary files created during mockup exploration, or commit them if they're the selected direction
- Ensure the working tree is clean

### Step 6: Completion Screen

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✓ Design Selected — Mockup {N}: {name/description}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Mockups presented  {N}
  Selected           Mockup {N}
  Documented in      .claude/plans/{issue}-{feature}.md ✓

─────────────────────────────────────────────────────────────────
  ▶ Next    /z-work {issue} 1
            Begin implementation with selected design

            /clear first — fresh context
─────────────────────────────────────────────────────────────────

  Also available:
    · /z-plan {issue} --verify — verify plan first

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
