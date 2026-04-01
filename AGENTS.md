# Chatwoot Development Guidelines

## Build / Test / Lint

- **Setup**: `bundle install && pnpm install`
- **Run Dev**: `pnpm dev` or `overmind start -f ./Procfile.dev`
- **Lint JS/Vue**: `pnpm eslint` / `pnpm eslint:fix`
- **Lint Ruby**: `bundle exec rubocop -a`
- **Test JS**: `pnpm test` or `pnpm test:watch`
- **Test Ruby**: `bundle exec rspec spec/path/to/file_spec.rb`
- **Single Test**: `bundle exec rspec spec/path/to/file_spec.rb:LINE_NUMBER`
- **Run Project**: `overmind start -f Procfile.dev`
- **Ruby Version**: Manage Ruby via `rbenv` and install the version listed in `.ruby-version`
- **rbenv setup**: Before running any `bundle` or `rspec` commands, run `eval "$(rbenv init -)"`
- Always use `bundle exec` for Ruby CLI tasks.

## Design System (Mandatory)

- **Primary Source**: Stitch project `Design Tokens & Typography` (`15998668293997990973`).
- **Current Baseline Screen**: `Buttons & Forms Components (Updated)` (`95d53b034f554b0c8512b877fdb7d4a7`).
- **Theme Direction**: Dark-first Cybros visual system.
- **Typography**: Use `Inter` for headline/body/label.
- **Token Source of Truth**:
  - Tailwind semantic tokens in `theme/colors.js`
  - Tailwind setup in `tailwind.config.js`
  - CSS variable bridge in `app/javascript/dashboard/assets/scss/_next-colors.scss`
- **Do not invent colors ad-hoc** in components. Use semantic tokens (e.g. `secondary`, `surface-container-low`, `on-surface`).
- **Radii scale**:
  - default: `4px`
  - `lg`: `8px`
  - `xl`: `12px`
  - `full`: `9999px`

## Styling Rules

- Prefer Tailwind utility classes in Vue templates.
- If SCSS is needed, consume existing CSS variables; do not hardcode random hex values.
- No inline styles unless absolutely unavoidable.
- Keep visual language consistent with Stitch tokens across dashboard screens.

## Implementation Guidelines

- MVP first with minimal, readable changes.
- Avoid unnecessary abstractions and defensive code.
- Break larger UI migrations into small, testable slices.
- Avoid writing specs unless explicitly requested.
- Remove dead/unused code during touched-area refactors.

## i18n and Frontend

- No bare strings in templates; use i18n.
- Only update `en.yml` and `en.json` for translations.
- Use `components-next/` for new dashboard UI work.
- Use Vue Composition API with `<script setup>`.

## Ruby and Backend

- Follow RuboCop rules (150 char max line length).
- Use compact module/class definitions.
- Use strong params and model validations/indexes where applicable.

## Enterprise Compatibility

- Check matching paths in `enterprise/` when changing shared behavior.
- Prefer extension points (`prepend_mod_with`/`include_mod_with`) for Enterprise-specific changes.
- Keep request/response contracts aligned between OSS and Enterprise.
- Reference: https://chatwoot.help/hc/handbook/articles/developing-enterprise-edition-features-38

## Commit Messages

- Prefer Conventional Commits: `type(scope): subject`
- Example: `feat(ui): align dashboard with stitch design tokens`
- Do not reference Claude in commit messages.
