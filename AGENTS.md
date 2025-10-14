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

### Time Picker with Images

**Key Discovery**: The `replyMessage` should automatically reuse the same `imageIdentifier` as `receivedMessage` when not explicitly set.

**Critical Implementation Details**:

1. **Automatic Image Fallback**:
   ```ruby
   # In SendTimePickerService#build_reply_message
   reply_image_id = content_attributes['reply_image_identifier'] || content_attributes['replyImageIdentifier']

   # If reply image is not specified, reuse the received image identifier
   if reply_image_id.blank?
     received_image_id = content_attributes['received_image_identifier'] || content_attributes['receivedImageIdentifier']
     reply_image_id = received_image_id
   end
   ```

2. **Why This Matters**:
   - Apple MSP best practice: reply message should display the same image as received message
   - Frontend may not always explicitly set `replyImageIdentifier`
   - Automatic fallback ensures visual consistency in the time picker flow
   - User sees the same image when selecting a time slot as when viewing the picker

3. **The Fix**:
   - `SendTimePickerService#build_reply_message` now checks if `reply_image_identifier` is blank
   - If blank/nil/empty, it automatically uses `received_image_identifier`
   - Supports both camelCase and snake_case for frontend compatibility
   - Ensures Apple receives consistent image identifiers in both received and reply messages

4. **Related Files**:
   - Service: `app/services/apple_messages_for_business/send_time_picker_service.rb`
   - Frontend Modal: `app/javascript/dashboard/components-next/message/modals/EnhancedTimePickerModal.vue`
   - Frontend Composer: `app/javascript/dashboard/components/widgets/conversation/ReplyBox/AppleMessagesComposer.vue`

### Apple Messages Forms with Images

**Key Implementation**: Forms now support `receivedMessage` and `replyMessage` with images, similar to Time Picker and List Picker.

**Critical Implementation Details**:

1. **Automatic Image Fallback**:
   ```ruby
   # In FormService#build_reply_message
   reply_image_id = reply_msg['image_identifier'] || reply_msg['imageIdentifier']

   # If reply image is not specified, reuse the received image identifier
   if reply_image_id.blank?
     received_msg = @form_config['received_message'] || {}
     received_image_id = received_msg['image_identifier'] || received_msg['imageIdentifier']
     reply_image_id = received_image_id
   end
   ```

2. **Frontend Integration**:
   - AppleFormBuilder.vue has a new "Messages" tab for configuring receivedMessage and replyMessage
   - Image selector with preview similar to Time Picker
   - Auto-sync: reply image automatically uses received image if not explicitly set
   - Upload button to add new images to the library

3. **Service Updates**:
   - `FormService#build_form_data` includes receivedMessage and replyMessage
   - `FormService#build_images_array` collects and encodes images
   - Supports both camelCase and snake_case for frontend compatibility

4. **Related Files**:
   - Service: `app/services/apple_messages_for_business/form_service.rb`
   - Frontend Modal: `app/javascript/dashboard/components-next/message/modals/AppleFormBuilder.vue`
   - Frontend Composer: `app/javascript/dashboard/components/widgets/conversation/ReplyBox/AppleMessagesComposer.vue`

## Database Access

- **NEVER use `psql` directly** - Claude Code runs in a macOS sandbox that blocks direct PostgreSQL access
- **ALWAYS use `rails runner`** for database queries:
  ```bash
  rails runner "puts User.count"
  rails runner "puts Message.last.inspect"
  rails runner "puts ActiveRecord::Base.connection.execute('SELECT version()').to_a"
  ```
- **Alternative**: Use `rails console` for interactive queries
- **Logs**: Check `log/development.log` for Rails database activity
- **Only ask user to run `psql`** if rails runner cannot accomplish the task

## Other Notes

- Remember to implement camelCase format for any functions
- Remember that any tailscale command requires privilege - ask user to execute them directly
- Do not push changes to git until i noticed you