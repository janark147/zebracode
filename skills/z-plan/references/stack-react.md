# React Planning Notes

Stack-specific considerations when creating a plan for a standalone React project (Vite, CRA, or custom bundler — NOT Next.js, which has its own file).

## Phase Structuring

- **Data layer first**: Plan API clients, hooks for data fetching (React Query/SWR/custom), and TypeScript types before UI components.
- **Hooks before components**: Shared logic lives in custom hooks. Plan `use*` hooks before the components that consume them.
- **Layout then features**: If a new page or section is needed, plan layout/shell components before feature-specific content.
- **State management scope**: Decide early whether state is component-local, context-based, or needs an external store. Plan accordingly — don't add Redux/Zustand mid-feature.

## Common Phase Patterns

- **Data layer phase**: API client functions + React Query hooks (or equivalent) + TypeScript interfaces
- **Component phase**: Component + hook (if complex logic) + CSS module/styled component
- **Page phase**: Route registration + page component + data loading + loading/error boundaries
- **Form phase**: Form component + validation (React Hook Form/Formik or controlled inputs) + submission handler + error display

## Planning Pitfalls

- **State management**: Check what the project uses (Context, Redux, Zustand, Jotai, React Query). Don't introduce a new state library without justification. React Query often eliminates the need for global state for server data.
- **Routing**: Check for React Router version (v5 vs v6 — significantly different API). Plan route definitions alongside page components.
- **CSS approach**: Check project convention — CSS Modules, Tailwind, styled-components, Emotion, plain CSS. Use the existing pattern.
- **Component patterns**: Check if project uses controlled vs uncontrolled components, forwardRef patterns, compound components. Match existing style.
- **Error boundaries**: Plan error boundary placement for new feature sections, especially around data-fetching components.
- **Memo/callback**: Don't plan premature optimization. Only note `useMemo`/`useCallback` when there's a demonstrated performance concern.

## Must-Have Considerations

- **Artifacts**: Include component files, hook files, type definition files, route registration update, test files
- **Links**: Route → Page component, Component → Hook usage, Hook → API client, Context Provider → Consumer components
- **Truths**: "Component renders {content} when {condition}" + "Loading state displays while data fetches" + "Error state handles {failure case} gracefully"
