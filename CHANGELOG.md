# Chatwoot Changes Log

## Custom Branding Integration

### [2023-06-01] Rebranding to LiveIQ with Purple Theme

#### Files Changed
- `public/brand-assets/logo.svg` - Created new SVG logo with LiveIQ branding
- `public/brand-assets/logo_dark.svg` - Created dark version of the logo
- `public/brand-assets/logo_thumbnail.svg` - Created favicon/icon version
- `theme/colors.js` - Updated brand color to #8A57DE (purple) and modified color scheme

### [2023-06-01] Captain to AI Agent Transformation

#### Model Renaming
- `CaptainInbox` → `AIAgentInbox`
- `Captain::Assistant` → `AIAgent::Topic`
- `Captain::Document` → `AIAgent::Document`
- `Captain::AssistantResponse` → `AIAgent::TopicResponse`

#### Files Changed
- `enterprise/app/models/captain_inbox.rb` → Renamed class and updated associations
- `enterprise/app/models/captain/assistant.rb` → Renamed class and updated references
- `enterprise/app/models/captain/document.rb` → Renamed class and updated references
- `enterprise/app/models/captain/assistant_response.rb` → Renamed class and updated references

#### Database Migrations
- Added `db/migrate/20250601000001_rename_captain_tables_to_ai_agent.rb` to rename tables and their columns

## Enhanced Conversation Features

### [2023-06-01] Content Attributes Implementation

#### Files Changed
- `app/models/conversation.rb` - Added content_attributes field with accessor methods
- `app/javascript/dashboard/components/widgets/conversation/ContentAttributes.vue` - Created new component to display content attributes
- `app/javascript/dashboard/i18n/locale/en/conversation.json` - Added translations for content attributes

#### Database Migrations
- Added `db/migrate/20250601000000_add_content_attributes_to_conversations.rb` to add the content_attributes field

## Documentation Updates

### [2023-06-01] Implementation Documentation
- Added `IMPLEMENTATION_DOCS.md` with detailed explanation of all changes
- Added `CHANGELOG.md` to track specific file changes 