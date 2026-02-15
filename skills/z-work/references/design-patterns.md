# Design Phase Handler

Loaded when the current phase has `**Type**: design`. This phase delegates to `/z-design` logic.

**MCP requirement**: This phase uses the **Magic MCP** (`mcp__magic__*`) instead of Context7. If Magic MCP is not available, inform the user and suggest manual mockup creation.

## Execution Flow

1. **Scan existing codebase for UI context**:
   - Find existing UI components, spacing conventions, icon sets, color tokens
   - Identify reusable components that can be leveraged for the new design
   - Note the CSS framework in use (from `z-project-config.yml` → `stack.css`)
   - Note the component library in use (from `z-project-config.yml` → `stack.frontend`)

2. **Generate mockup variations**:
   - Use Magic MCP (`mcp__magic__21st_magic_component_builder` or `mcp__magic__21st_magic_component_inspiration`) to generate mockup variations
   - Generate 5+ distinct variations with different approaches
   - Each variation should explore a different layout, interaction pattern, or visual treatment
   - Variations should respect the existing design language of the app

3. **Present to user for selection**:
   - Show each mockup with a brief description of its approach
   - Use AskUserQuestion: "Which mockup direction do you prefer? (You can combine elements from multiple.)"
   - Allow the user to request iterations or combinations

4. **Document the decision**:
   - Populate the plan's `## Design Decisions` section with:
     - Selected mockup description and rationale
     - Component inventory: new components vs reused existing ones
     - Layout approach and spacing decisions
     - Any deviations from existing design patterns (with justification)

5. **Complete the phase**: Standard must-haves verification, work log, completion screen apply. The key must-haves for a design phase are:
   - **Truth**: User has reviewed and selected a design direction
   - **Artifact**: Design Decisions section populated in the plan file
   - **Link**: Existing components identified for reuse are verified to exist
