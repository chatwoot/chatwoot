# EcoRay Chatwoot Fork

This is our forked version of Chatwoot for custom development.

## Setup Instructions

1. **Install Dependencies:**
   ```bash
   bundle install
   pnpm install
   ```

2. **Setup Ruby:**
   - Use rbenv to manage Ruby versions
   - Install the required Ruby version: `rbenv install $(cat .ruby-version)`
   - Initialize rbenv in your shell: `eval "$(rbenv init -)"`

3. **Development:**
   - Start dev server: `pnpm dev` or `overmind start -f ./Procfile.dev`
   - Lint JS/Vue: `pnpm eslint` / `pnpm eslint:fix`
   - Lint Ruby: `bundle exec rubocop -a`
   - Test JS: `pnpm test`
   - Test Ruby: `bundle exec rspec spec/path/to/file_spec.rb`

## Notes

- Ruby commands must use `bundle exec`
- Frontend uses Vue 3 with Composition API and Tailwind CSS
- No custom CSS allowed; only Tailwind utility classes
- Translation keys use i18n (en.yml for backend, en.json for frontend)
