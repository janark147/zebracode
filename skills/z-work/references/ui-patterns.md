# UI Implementation Patterns

Loaded when the current phase involves frontend/UI work (components, views, templates, styles).

## Implementation Checklist

When implementing UI components, ensure each has:

1. **Component structure** — matches existing project patterns (SFC for Vue, functional/class for React, etc.)
2. **Props/inputs** — properly typed with defaults where sensible. Use the project's prop validation approach.
3. **State management** — appropriate scope. Local state for component-specific data, store/context for shared state. Don't over-engineer.
4. **Event handling** — emits/callbacks follow project naming conventions. Form submissions handle loading + error states.
5. **Accessibility** — semantic HTML, ARIA labels on interactive elements, keyboard navigable, focus management for modals/dialogs
6. **Responsive behavior** — works on mobile if the app is responsive. Check existing breakpoint conventions.
7. **Loading and error states** — every data-dependent component has loading, error, and empty state handling
8. **Tests** — component rendering, user interaction, edge states (loading, error, empty data)

## Conventions to Check

Before writing UI code, verify these against the existing codebase:
- **Component naming**: PascalCase? kebab-case? What prefix conventions exist?
- **File organization**: Flat components directory? Feature-based folders? Atomic design?
- **CSS approach**: Tailwind? CSS Modules? Scoped styles? Styled components? SCSS? Match exactly.
- **Icon system**: What icon library? SVG sprites? Icon components? Don't introduce a new one.
- **Form handling**: What library or pattern? Controlled inputs? VeeValidate? React Hook Form?
- **Routing**: How are pages registered? Lazy loading? Route guards?
- **Component library**: Is there a UI kit (CoreUI, Vuetify, MUI, Shadcn)? Use its components before creating custom ones.

## Quality Reminders

- Reuse existing components before creating new ones. Check the component library first.
- Never hardcode strings that should be translatable (if i18n is set up)
- Sanitize HTML content before rendering with `v-html` or `dangerouslySetInnerHTML`
- Debounce search inputs and other rapid-fire events
- Optimistic UI updates should have rollback on failure
- Keep component files focused — extract sub-components when a file exceeds ~200 lines
