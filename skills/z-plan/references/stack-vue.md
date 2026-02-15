# Vue.js Planning Notes

Stack-specific considerations when creating a plan for a project using Vue.js as the frontend.

## Phase Structuring

- **Backend before frontend**: If the feature has both backend and frontend work, plan API/data phases before Vue component phases. Components need endpoints or data contracts to build against.
- **Composables before components**: If shared logic is needed (data fetching, form handling, state), plan composable creation before the components that consume them.
- **Component hierarchy top-down**: Plan parent/layout components before child components. Props and events flow down and up — parent structure determines child interfaces.
- **Inertia.js consideration**: If the project uses Inertia (common with Laravel), plan page components as Inertia pages. Shared data comes from HandleInertiaRequests middleware, not API calls.

## Common Phase Patterns

- **Component phase**: Vue SFC (.vue) + composable (if logic is reusable) + types/interfaces
- **Page phase (Inertia)**: Inertia page component + Laravel controller props + shared data middleware
- **Page phase (SPA)**: Vue Router route + page component + API client calls + loading/error states
- **Store phase**: Pinia store + actions + getters (only if shared cross-component state is needed)
- **Form phase**: Form component + validation (VeeValidate/FormKit or manual) + API submission + error handling

## Planning Pitfalls

- **Options API vs Composition API**: Check which API style the project uses. Don't mix — use the same style as existing components.
- **Pinia vs Vuex vs no store**: Check for existing store library. Don't introduce Pinia if the project uses Vuex (or vice versa). Many features don't need a store at all — props and emits are sufficient.
- **Vue 2 vs Vue 3**: Critical distinction. Vue 2 uses Options API, `this.$emit`, `Vue.set()`. Vue 3 uses `<script setup>`, `defineEmits()`, reactive refs. Check `package.json` for version.
- **Component library**: Check for existing UI library (CoreUI, Vuetify, PrimeVue, Element Plus, etc.). Plan to reuse existing components, not create duplicates.
- **Routing guards**: If the feature involves auth-gated pages, plan navigation guards in the phase that creates the route, not separately.
- **TypeScript integration**: If the project uses TypeScript, plan `defineProps<T>()` and `defineEmits<T>()` type definitions. Plan interface files for complex prop types.

## Must-Have Considerations

- **Artifacts**: Include `.vue` component files, composables, type definitions, route registration (if new page), store module (if needed)
- **Links**: Parent → Child component imports, Route → Page component mapping, Composable → Component usage, Store → Component injection
- **Truths**: "Component renders {content}" + "User interaction {action} triggers {result}" + "Form validation blocks submission on {invalid state}"
