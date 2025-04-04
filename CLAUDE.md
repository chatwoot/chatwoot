@@ -0,0 +1,21 @@
# Chatwoot Development Guidelines

## Build/Test/Lint Commands
- **Setup**: `bundle install && pnpm install` 
- **Run Dev**: `pnpm dev` (or `overmind start -f ./Procfile.dev`)
- **Lint JS/Vue**: `pnpm eslint` / `pnpm eslint:fix`
- **Lint Ruby**: `bundle exec rubocop -a`
- **Test JS**: `pnpm test` or `pnpm test:watch`
- **Test Ruby**: `bundle exec rspec spec/path/to/file_spec.rb` 
- **Single Test**: `bundle exec rspec spec/path/to/file_spec.rb:LINE_NUMBER`
- **Run Project**: `overmind start -f Procfile.dev`

## Code Style Guidelines
- **Ruby**: Follow RuboCop rules (150 char line length max)
- **JS/Vue**: Follow ESLint rules (AirBnB base + Vue 3 recommended)
- **Vue Components**: Use PascalCase for component names
- **Events**: Use camelCase for custom event names
- **I18n**: Avoid bare strings in templates, use i18n
- **Error Handling**: Use custom exceptions from `lib/custom_exceptions/`
- **Models**: Validate presence/uniqueness, use appropriate indexes
- **Type Safety**: Use PropTypes in Vue, strong params in Rails
- **Naming**: Descriptive, consistent casing per language convention

## General Instructions
- Focus on generating the mvp with least amount of code changes
- Generate spec only when asked to
- Don't reference claude when generating commit messages

## Project specific data
- Translations only need to be applied to the en.yml and json files, other langauge translations are handled by community translators so no need to update
