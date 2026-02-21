# AI Usage Log - Pinned Message Feature

## Assignment Context

Implementing a "Pinned Message in Conversation" feature for Chatwoot as part of a job application assessment.

## Tools Used

- **Primary AI**: Claude 3.5 Sonnet via Cursor AI/GitHub Copilot
- **Additional Tools**: VS Code with Ruby LSP, ESLint, Docker
- **Environment**: Windows with Docker Desktop

## Development Workflow

### Phase 1: Codebase Analysis (Current)

**Objective**: Understand Chatwoot's architecture before implementing changes

#### AI-Assisted Analysis Steps:

1. **Model Structure Discovery**

   - Asked AI to explain Conversation and Message models
   - Examined schema definitions and relationships
   - Identified that Conversation has `belongs_to :account, :inbox, :contact`
   - Discovered Message `belongs_to :conversation`

2. **Controller Pattern Understanding**

   - Located messages controller at `app/controllers/api/v1/accounts/conversations/messages_controller.rb`
   - Identified RESTful pattern and authorization flow
   - Noted use of `BaseController` inheritance

3. **Database Schema Review**
   - Examined `db/schema.rb` for table structures
   - Identified foreign key patterns and index conventions
   - Noted JSONB usage for flexible attributes

### AI Prompts Used

#### Prompt 1: Initial Code Understanding

```
Explain how Chatwoot stores conversations and messages in the database.
Show me the relationship between Conversation and Message models.
```

**AI Response**: Provided schema structure and ActiveRecord associations

**What I Accepted**: The relationship explanation and schema details

**What I Rejected**: AI suggested storing pinned_message as JSONB in additional_attributes,
but I decided a dedicated column would be better for indexing and referential integrity

---

#### Prompt 2: Controller Structure

```
Show me how Chatwoot structures its API controllers for messages.
What's the pattern for adding new actions to message controllers?
```

**AI Response**: Explained RESTful routing and controller inheritance pattern

**What I Accepted**: The controller structure and routing conventions

**What I Rejected**: N/A - accepted the explanation as-is

---

#### Prompt 3: Migration Creation

```
Create a Rails migration to add pinned_message_id to conversations table.
Include proper foreign key constraint and index for performance.
```

**AI Response**: Generated migration with `add_reference` using foreign key to messages table with on_delete: :nullify

**What I Accepted**:

- Using `add_reference` helper (Rails convention)
- Foreign key constraint with cascade rule
- Index for query performance

**What I Rejected**: N/A - migration follows Rails best practices

---

#### Prompt 4: Model Association

```
Update Conversation model to add belongs_to :pinned_message association
with validation to ensure the pinned message belongs to this conversation
```

**AI Response**: Added belongs_to with custom validation method

**What I Accepted**:

- `belongs_to :pinned_message, class_name: 'Message', optional: true`
- Custom validator checking conversation_id match

**What I Rejected**: N/A - follows Chatwoot's validation pattern

---

### Phase 3: Controller Implementation (Completed ✓)

#### Prompt 5: Controller Actions

```
Add pin and unpin actions to messages controller following Chatwoot's patterns.
Ensure proper view rendering and error handling.
```

**AI Response**:

- Created pin/unpin actions in messages controller
- Added view files (pin.json.jbuilder, unpin.json.jbuilder) rendering conversation partial
- Added routes with POST for pin, DELETE for unpin
- Used update! with proper error handling via rescue

**What I Accepted**:

- View-based rendering (following update/destroy/retry pattern)
- Automatic broadcast via after_update_commit callback
- Simple controller actions delegating to model

**What I Rejected**:

- Initial attempt at manual broadcasting (Chatwoot handles this automatically via model callbacks)
- Initial attempt at using head :ok without view rendering
- Manual authorize calls (base controller already handles authorization)

---

### Phase 4: Testing (Completed ✓)

**Model Tests**: 3/3 passed ✓

- Association test
- Valid pinning within same conversation
- Prevents pinning from different conversation
- Allows clearing pinned message

**Controller Tests**: 4/5 passed ✓

- Pin action creates pinned_message
- Pin action replaces existing pinned_message
- Unpin action clears pinned_message
- Unpin action rejects non-pinned messages
- Authorization tests (unauthenticated users rejected)

Note: 1 test failure is Redis-related test infrastructure issue (auto-assignment service), not related to pinned message feature.

---

## Validation Methods

### Code Correctness

- [x] Run `bundle exec rspec spec/models/conversation_spec.rb -e "validate pinned_message"` - 3/3 passed
- [x] Run `bundle exec rspec spec/controllers/...` - 4/5 passed (1 Redis setup issue)
- [ ] Manual testing in browser
- [ ] Test with multiple agents simultaneously

### Linting & Standards

- [ ] Run `bundle exec rubocop -a` (Ruby)
- [ ] Run `pnpm eslint:fix` (JavaScript/Vue)
- [x] Check Chatwoot coding guidelines in AGENTS.md

---

## Implementation Summary

### Backend Changes

1. **Migration**: `db/migrate/20260220115938_add_pinned_message_to_conversations.rb`

   - Adds `pinned_message_id` foreign key to conversations table
   - Includes index for performance
   - On delete: nullify to prevent orphaned references

2. **Model**: `app/models/conversation.rb`

   - Added `belongs_to :pinned_message, class_name: 'Message', optional: true`
   - Custom validation ensuring pinned message belongs to conversation
   - Added `pinned_message_id` to `list_of_keys` for automatic broadcasting

3. **Controller**: `app/controllers/api/v1/accounts/conversations/messages_controller.rb`

   - Added `pin` action (POST)
   - Added `unpin` action (DELETE)
   - Proper error handling with ActiveRecord::RecordInvalid rescue

4. **Routes**: `config/routes.rb`

   - POST `/messages/:id/pin`
   - DELETE `/messages/:id/unpin`

5. **Views**:

   - `app/views/api/v1/accounts/conversations/messages/pin.json.jbuilder`
   - `app/views/api/v1/accounts/conversations/messages/unpin.json.jbuilder`
   - Updated `app/views/api/v1/conversations/partials/_conversation.json.jbuilder` to include pinned_message

6. **Tests**:
   - Model tests in `spec/models/conversation_spec.rb`
   - Controller tests in `spec/controllers/api/v1/accounts/conversations/messages_controller_spec.rb`

### Key Design Decisions

- Foreign key over JSONB for referential integrity
- Automatic broadcasting via model callbacks (no manual dispatcher calls)
- View-based response rendering (consistent with Chatwoot patterns)
- Validation at model level (ensures data integrity)

---

---

### Phase 5: Frontend Implementation (Completed ✓)

#### Prompt 6: API Client Methods

```
Add pinMessage and unpinMessage methods to dashboard/api/inbox/message.js
following the pattern of delete() and retry()
```

**AI Response**: Added two new methods to MessageApi class:

- `pinMessage(conversationId, messageId)` - POST to pin endpoint
- `unpinMessage(conversationId, messageId)` - DELETE to pin endpoint

**What I Accepted**: Clean API method structure matching existing Chatwoot patterns

**What I Rejected**: N/A

---

#### Prompt 7: Message Context Menu Integration

```
Add handlePinMessage() and handleUnpinMessage() handlers to MessageContextMenu.vue
Import messageAPI and call pin/unpin endpoints with proper error handling
```

**AI Response**:

- Imported messageAPI
- Added async handlers with try/catch blocks
- Used useAlert for success/error messages
- Called handleClose() after operations

**What I Accepted**:

- Error handling pattern matching other actions (handleCopy, handleTranslate)
- Toast notification approach
- Async/await syntax

**What I Rejected**: N/A - follows existing component patterns

---

#### Prompt 8: Context Menu UI

```
Add MenuItem components for pin/unpin in MessageContextMenu template.
Show "Pin message" when not pinned, "Unpin message" when pinned.
Add proper separator <hr> before pin/unpin items.
```

**AI Response**:

- Added MenuItem for pin with v-if="enabledOptions['pin']"
- Added MenuItem for unpin with v-if="enabledOptions['unpin']"
- Added <hr> separator before pin/unpin section

**What I Accepted**: Clean template structure with conditional rendering

**What I Rejected**: N/A

---

#### Prompt 9: Enable Pin/Unpin Options

```
Update Message.vue to add pin/unpin to contextMenuEnabledOptions computed property.
Access conversation from Vuex store to check pinned_message_id.
Pass pinned_message_id to MessageContextMenu via payloadForContextMenu.
```

**AI Response**:

- Added conversationGetter from useMapGetter
- Computed conversation object
- Added isPinned check in contextMenuEnabledOptions
- Added pin/unpin boolean options based on isPinned and message status
- Updated payloadForContextMenu to include pinned_message_id

**What I Accepted**:

- Store-based conversation access
- Clean computed property logic
- Proper pin/unpin mutual exclusivity

**What I Rejected**: N/A

---

#### Prompt 10: PinnedMessage Display Component

```
Create PinnedMessage.vue component to display pinned message at top of conversation.
Show sender name, truncated message content, pin icon, and unpin button.
Use Tailwind classes following Chatwoot design system.
```

**AI Response**:

- Created component with Composition API (script setup)
- Truncates content to 100 characters
- Shows sender name with fallback to i18n "Unknown" text
- Unpin button calls messageAPI.unpinMessage
- Uses Tailwind utility classes for styling
- Uses fluent-icon for pin icon, NextButton for unpin

**What I Accepted**:

- Composition API structure
- Truncation logic for long messages
- Tailwind-only styling (no custom CSS)
- Component structure

**What I Rejected**:

- N/A - follows Chatwoot component patterns

**Note**: Small warning about raw text ":" in template - acceptable for MVP, can be i18n'd later if needed

---

#### Prompt 11: Integrate PinnedMessage into MessageList

```
Import PinnedMessage in MessageList.vue.
Add computed property to find pinned message from messages array.
Display PinnedMessage at top of <ul> when conversation has pinned_message_id.
```

**AI Response**:

- Imported PinnedMessage component
- Added pinnedMessage computed property using allMessages.find()
- Added <PinnedMessage> before message loop with v-if guard
- Passed message and conversationId props

**What I Accepted**:

- Efficient lookup from existing messages array
- Clean v-if conditional rendering
- Proper prop passing

**What I Rejected**: N/A

---

#### Prompt 12: i18n Translations

```
Add translations to app/javascript/dashboard/i18n/locale/en/conversation.json:
- CONTEXT_MENU.PIN_MESSAGE
- CONTEXT_MENU.UNPIN_MESSAGE
- CONTEXT_MENU.PIN_SUCCESS/ERROR
- CONTEXT_MENU.UNPIN_SUCCESS/ERROR
- PINNED_MESSAGE.TITLE/UNPIN/UNKNOWN_SENDER
```

**AI Response**: Added all required translation keys with clear English text

**What I Accepted**: All translation strings

**What I Rejected**: N/A

---

### Frontend Files Modified

1. **API Client**: `app/javascript/dashboard/api/inbox/message.js`

   - Added pinMessage() and unpinMessage() methods

2. **Message Context Menu**: `app/javascript/dashboard/modules/conversations/components/MessageContextMenu.vue`

   - Imported messageAPI
   - Added handlePinMessage() and handleUnpinMessage() handlers
   - Added MenuItem components for pin/unpin with conditional rendering

3. **Message Component**: `app/javascript/dashboard/components-next/message/Message.vue`

   - Added conversation getter from Vuex store
   - Updated contextMenuEnabledOptions with pin/unpin logic
   - Updated payloadForContextMenu to include pinned_message_id

4. **Message List**: `app/javascript/dashboard/components-next/message/MessageList.vue`

   - Imported PinnedMessage component
   - Added pinnedMessage computed property
   - Rendered PinnedMessage at top of message list

5. **Pinned Message Display**: `app/javascript/dashboard/components-next/message/PinnedMessage.vue` (new file)

   - Created display component with Composition API
   - Truncates long messages
   - Shows sender, content, unpin button
   - Tailwind-only styling

6. **Translations**: `app/javascript/dashboard/i18n/locale/en/conversation.json`
   - Added CONTEXT_MENU.PIN_MESSAGE, UNPIN_MESSAGE, etc.
   - Added PINNED_MESSAGE.TITLE, UNPIN, UNKNOWN_SENDER

---

## Frontend AI Rejections

### Rejection 3: Vuex Store Actions

**AI Consideration**: Should we create Vuex actions for pin/unpin?

**Why Rejected**:

- Backend automatically broadcasts conversation.updated via ActionCable
- Vuex store already listens to conversation.updated events
- Adding store actions would be redundant
- API calls directly from component is simpler for this use case

**Alternative Chosen**: Direct API calls from MessageContextMenu, let existing ActionCable handlers update store

---

## Validation Methods

### Code Correctness

- [x] Run `bundle exec rspec spec/models/conversation_spec.rb` - 3/3 passed ✓
- [x] Run `bundle exec rspec spec/controllers/...` - 4/5 passed (1 Redis infrastructure issue) ✓
- [ ] Manual testing in browser
- [ ] Test with multiple agents simultaneously
- [ ] Test pin/unpin with multiple browser tabs (real-time updates)

### Linting & Standards

- [x] Run `bundle exec rubocop -a` (Ruby) - Clean except Windows CRLF ✓
- [x] Run `pnpm eslint:fix` (Frontend) - Clean, 0 errors, 359 warnings (all acceptable) ✓
- [x] Check Chatwoot coding guidelines in AGENTS.md ✓

---

## Implementation Checklist

- [x] Database migration ✓
- [x] Model associations and validations ✓
- [x] API endpoints (pin/unpin) ✓
- [x] Authorization policy (handled by BaseController) ✓
- [x] Backend tests ✓
- [x] Frontend Vue components ✓
- [ ] Frontend tests (deferred for MVP)
- [x] Realtime broadcast via ActionCable (automatic via list_of_keys) ✓
- [x] Documentation (TESTING_PINNED_MESSAGE.md) ✓
- [ ] Screenshots/GIF (after manual testing)

---

## AI Rejections Log

### Rejection 1: Storage Location

**AI Suggestion**: Store pinned message data in `conversation.additional_attributes` as JSONB

**Why Rejected**:

- No referential integrity (can't enforce foreign key)
- Can't create database index for performance
- Harder to query and join
- Not following Chatwoot's pattern for entity relationships

**Alternative Chosen**: Add `pinned_message_id` as a proper foreign key column

---

### Rejection 2: Manual Broadcasting

**AI Initial Suggestion**: Manually call Rails.configuration.dispatcher.dispatch() after pin/unpin

**Why Rejected**:

- Chatwoot uses automatic broadcasting via after_update_commit callback
- Manual dispatch would duplicate broadcasts
- Adding pinned_message_id to list_of_keys handles this automatically
- Simpler and more maintainable

**Alternative Chosen**: Add pinned_message_id to list_of_keys whitelist in Conversation model

---

### Rejection 3: Vuex Store Actions

**AI Consideration**: Should we create dedicated Vuex actions for pin/unpin?

**Why Rejected**:

- Backend automatically broadcasts via ActionCable
- Vuex store already handles conversation.updated events
- Direct API calls from component are simpler
- No need for redundant store actions

**Alternative Chosen**: Direct messageAPI calls, rely on existing ActionCable handlers

---

## Testing Documentation

See `TESTING_PINNED_MESSAGE.md` for comprehensive testing guide including:

- Backend test results
- Manual browser testing steps
- Real-time update verification
- Error handling scenarios
- Performance considerations
- Known limitations

---

_This log documents all AI interactions during the implementation of the Pinned Message feature_
