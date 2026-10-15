---
argument-hint: "[issue]"
description: "Generate multiple UI/UX design mockups for an issue"
---

# /z-design — UI/UX Mockup Generator

Operates in two modes:
- **Standalone** (this skill, invoked directly) — ad-hoc design exploration
- **Phase handler** (invoked by `/z-work` for `Type: design` phases) — `z-work/references/design-patterns.md` points back to the Execution steps below

## Pre-flight Validation

**Run these checks FIRST.**

1. **Design skill check**: Confirm `frontend-design:frontend-design` is in your list of available skills (it comes from the `frontend-design@claude-plugins-official` plugin). Do not invoke it just to test. If absent → display validation-failed screen.
2. **Predecessor check**: Check that a plan file exists in `.claude/plans/` matching the issue or branch. If no plan file found → display blocked screen and redirect to `/z-plan {issue}`.

### Validation-Failed Screen

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✗ Design — Pre-flight Failed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ✗ frontend-design skill not available

─────────────────────────────────────────────────────────────────
  ▶ Fix      claude plugin install frontend-design@claude-plugins-official
             Then restart Claude Code
─────────────────────────────────────────────────────────────────
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Blocked Screen

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✗ Design Blocked — no plan file found
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Required     Plan file must exist
  Missing      .claude/plans/{issue}-*.md

─────────────────────────────────────────────────────────────────
  ▶ Run first  /z-plan {issue}
               Create an implementation plan
─────────────────────────────────────────────────────────────────
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Argument Parsing

- **Issue ID**: First positional argument. If not provided, derive from current branch name.
- Read plan file: `.claude/plans/{issue}.md` or `.claude/plans/{issue}-*.md`.

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

### Step 2: Load the Design Skill

Invoke the Skill tool with `frontend-design:frontend-design` and follow its process for every mockup: design plan → review the plan against the brief → build → critique. Apply these rules on top of it:

- **The brief is the existing app.** When Step 1 found an established design language, that language is the brief's visual direction — the design skill says the brief's own words win. Reuse the app's palette, typefaces and components. Put the skill's deliberate, distinctive choices into layout, hierarchy, content and interaction, not into a new visual identity.
- **New look only when there is nothing to match.** If the project has no established design yet, or the issue asks for a new look, the design skill applies in full: give each mockup its own token system (palette, type, layout, principles).
- **Real content.** Use the issue's real content and the app's real data shapes (field names, realistic values, empty and error states), not lorem ipsum.

### Step 3: Generate Mockups

Provide at least **5 distinct mockup variations**, each exploring a different approach:

- Different layouts (sidebar vs tabs vs accordion vs wizard, etc.)
- Different interaction patterns (inline editing vs modal, progressive disclosure vs all-at-once, etc.)
- Different visual treatments within the existing design language
- Different component compositions using existing building blocks

For each mockup:
1. Write it as a self-contained HTML file: `.claude/.local/mockups/{issue}/{N}-{short-name}.html`. Load the project's CSS framework from a CDN where it has one (e.g., the Tailwind browser build) and copy the app's real tokens (colors, fonts, spacing, radii) into the file, so it renders standalone and looks like the app.
2. Provide as much **live functionality** as possible — working buttons, real layouts, interactive elements, the states the issue needs (empty, loading, error).
3. If a mockup only makes sense inside the running app, you may temporarily modify existing files to show it in context — list every such change so Step 6 can revert it.
4. Give each mockup a brief label and a one-line description of its approach.
5. If browser tools are available, open each mockup, take a screenshot and critique it before presenting (the design skill's self-critique step). Otherwise give the user the file paths (`open {path}` on macOS).

### Step 4: Generic-Design Check

Before presenting, check every mockup against named patterns. A general instruction such as "avoid a generic AI look" mostly swaps one default style for another; naming the specific patterns works (Anthropic's Claude Opus 5.5 prompting guide, "Frontend design defaults"). The design skill already lists the main clusters (cream + serif + terracotta, near-black + acid green, broadsheet hairlines, the SaaS card kit, template chrome). Also check for these, which it does not list:

- A purple, indigo or blue-to-purple gradient or accent (Tailwind's old `indigo-500` default) that the app does not already use
- Inter, Roboto or the system font chosen by default rather than taken from the app or picked for the brief
- A centered hero with one CTA followed by a row of three icon feature boxes
- Pill-shaped buttons the app does not already use

Where the existing app already uses one of these, keep it — matching the app comes first.

Then compare the mockups with each other: if two differ only in color or font, replace one with a different layout or interaction approach. When iterating (Step 5), note which default styles the previous round fell back to and add them to this list for the next round.

### Step 5: Present to User

Use **AskUserQuestion** to present all mockups and let the user choose:
- "Which mockup direction do you prefer? You can combine elements from multiple."
- Allow iteration — if the user wants to explore a direction further, generate variations on that theme (Steps 2–4 again)
- Keep iterating until the user is satisfied with a direction

### Step 6: Document the Decision

After the user selects a mockup, update the plan file's `## Design Decisions` section:

- Selected mockup name/number and description
- Component inventory: new components to create vs existing ones to reuse
- Layout approach and rationale
- Any deviations from existing design patterns (with justification)

**Append, don't overwrite** — preserve history of design iterations if this skill is invoked multiple times.

### Step 7: Clean Up

- Revert any temporary in-app changes listed in Step 3
- Ask the user whether to keep the selected mockup in the repository and where (e.g., `docs/design/`). If yes, move it there and reference its path in Design Decisions. Delete the other mockup files.
- Ensure the working tree contains no leftover mockup changes

### Step 8: Completion Screen

**━━━ ✓ Design Selected ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━**
**Mockup {N}: {name/description}**

| | |
|---|---|
| **Mockups presented** | {N} |
| **Selected** | Mockup {N} |
| **Documented in** | `.claude/plans/{issue}-{feature}.md` ✓ |

───────────────────────────────────────────────────────────────
**▶ Next** · `/z-work {issue} 1` — begin implementation with selected design

*`/clear` first — fresh context*

**Also available:**
- `/z-plan {issue} --verify` — verify plan first

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
