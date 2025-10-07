# Chatwoot Development Guidelines

## Build / Test / Lint

- **Setup**: `bundle install && pnpm install`
- **Run Dev**: `./dev-server.sh start` (localhost only) or `./dev-server.sh start-public` (with public access)
- **Server Management**: `./dev-server.sh {start|start-public|stop|restart|status|help}`
- **Public Access Options**: Custom domain, Tailscale Funnel, or ngrok (configured in dev-server.sh)
- **Lint JS/Vue**: `pnpm eslint` / `pnpm eslint:fix`
- **Lint Ruby**: `bundle exec rubocop -a`
- **Test JS**: `pnpm test` or `pnpm test:watch`
- **Test Ruby**: `bundle exec rspec spec/path/to/file_spec.rb`
- **Single Test**: `bundle exec rspec spec/path/to/file_spec.rb:LINE_NUMBER`
- **Legacy Run**: `overmind start -f Procfile.dev` (use dev-server.sh instead)

## Code Style

- **Ruby**: Follow RuboCop rules (150 character max line length)
- **Vue/JS**: Use ESLint (Airbnb base + Vue 3 recommended)
- **Vue Components**: Use PascalCase
- **Events**: Use camelCase
- **I18n**: No bare strings in templates; use i18n
- **Error Handling**: Use custom exceptions (`lib/custom_exceptions/`)
- **Models**: Validate presence/uniqueness, add proper indexes
- **Type Safety**: Use PropTypes in Vue, strong params in Rails
- **Naming**: Use clear, descriptive names with consistent casing
- **Vue API**: Always use Composition API with `<script setup>` at the top

## Styling

- **Tailwind Only**:  
  - Do not write custom CSS  
  - Do not use scoped CSS  
  - Do not use inline styles  
  - Always use Tailwind utility classes  
- **Colors**: Refer to `tailwind.config.js` for color definitions

## General Guidelines

- MVP focus: Least code change, happy-path only
- No unnecessary defensive programming
- Break down complex tasks into small, testable units
- Iterate after confirmation
- Avoid writing specs unless explicitly asked
- Remove dead/unreachable/unused code
- Don’t write multiple versions or backups for the same logic — pick the best approach and implement it
- Don't reference Claude in commit messages

## Project-Specific

- **Translations**:
  - Only update `en.yml` and `en.json`
  - Other languages are handled by the community
  - Backend i18n → `en.yml`, Frontend i18n → `en.json`
- **Frontend**:
  - Use `components-next/` for message bubbles (the rest is being deprecated)

## Ruby Best Practices

- Use compact `module/class` definitions; avoid nested styles

## Enterprise Edition Notes

- Chatwoot has an Enterprise overlay under `enterprise/` that extends/overrides OSS code.
- When you add or modify core functionality, always check for corresponding files in `enterprise/` and keep behavior compatible.
- Follow the Enterprise development practices documented here:
  - https://chatwoot.help/hc/handbook/articles/developing-enterprise-edition-features-38

Practical checklist for any change impacting core logic or public APIs
- Search for related files in both trees before editing (e.g., `rg -n "FooService|ControllerName|ModelName" app enterprise`).
- If adding new endpoints, services, or models, consider whether Enterprise needs:
  - An override (e.g., `enterprise/app/...`), or
  - An extension point (e.g., `prepend_mod_with`, hooks, configuration) to avoid hard forks.
- Avoid hardcoding instance- or plan-specific behavior in OSS; prefer configuration, feature flags, or extension points consumed by Enterprise.
- Keep request/response contracts stable across OSS and Enterprise; update both sets of routes/controllers when introducing new APIs.
- When renaming/moving shared code, mirror the change in `enterprise/` to prevent drift.
- Tests: Add Enterprise-specific specs under `spec/enterprise`, mirroring OSS spec layout where applicable.
- Remember that any tailscale command as privilege Claude cannot use, please ask me diretly to execute them
- keep in memory the Vue configuration requirement

## Apple Messages for Business (AMB) - Critical Implementation Notes

### List Picker with Images

**Key Discovery**: The frontend sends `imageIdentifier` in **camelCase**, not `image_identifier` (snake_case).

**Service Architecture**:
- Parent: `AppleMessagesForBusiness::SendMessageService` (base class)
- Child: `AppleMessagesForBusiness::SendListPickerService` (overrides `build_list_picker_data`)

**Critical Implementation Details**:

1. **Child Class Override MUST Check Both Cases**:
   ```ruby
   # CORRECT - Check both camelCase and snake_case
   if item['image_identifier'].present?
     transformed_item['imageIdentifier'] = item['image_identifier']
   elsif item['imageIdentifier'].present?
     transformed_item['imageIdentifier'] = item['imageIdentifier']
   end
   ```

2. **Why This Matters**:
   - Vue/JavaScript frontend naturally uses camelCase: `imageIdentifier`
   - Rails typically uses snake_case: `image_identifier`
   - The `content_attributes` hash preserves the original casing from JSON
   - Apple MSP API expects camelCase: `imageIdentifier`

3. **The Bug That Was Fixed**:
   - Original code only checked `item['image_identifier']` (snake_case)
   - Frontend was sending `item['imageIdentifier']` (camelCase)
   - Result: `imageIdentifier` was silently dropped from the payload
   - Apple received list picker items without image references

4. **Image Storage Flow**:
   - Images are base64-encoded on frontend
   - Sent to backend in `content_attributes['images']`
   - Stored in ActiveStorage via `AppleListPickerImage` model
   - Retrieved and re-encoded when sending to Apple MSP
   - Items reference images via `imageIdentifier` matching the image's `identifier`

5. **Debugging Tips**:
   - Check final payload with: `payload[:interactiveData][:data][:listPicker][:sections].first['items'].first.keys`
   - Should include: `["identifier", "title", "subtitle", "order", "style", "imageIdentifier"]`
   - If `imageIdentifier` is missing, check the casing in `content_attributes`

6. **Related Files**:
   - Service: `app/services/apple_messages_for_business/send_list_picker_service.rb`
   - Model: `app/models/apple_list_picker_image.rb`
   - Controller: `app/controllers/api/v1/accounts/inboxes/apple_list_picker_images_controller.rb`
- always check the logs as you can't access the postgreSQL database directly
- remember to implement camelCase format for any functions