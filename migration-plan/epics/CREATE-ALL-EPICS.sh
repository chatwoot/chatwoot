#!/bin/bash

# This script creates all remaining epic plan files

# Epic 07: API v1 Core
cat > phase-3-api-layer/epic-07-api-v1-core.md << 'EOF'
# Epic 07: API v1 Core Endpoints

## Overview
- **Duration**: 1.5 weeks
- **Complexity**: High
- **Dependencies**: Epic 03-06 (all models)
- **Team Size**: 3-4 engineers
- **Can Parallelize**: Yes (by controller group)

## Scope: ~40 Core Controllers

### Account & User Management (8 controllers)
- AccountsController
- UsersController
- ProfilesController  
- AgentsController
- AgentBotsController
- TeamMembersController (agent management)
- PasswordsController
- SessionsController

### Conversations & Messages (10 controllers)
- ConversationsController
- MessagesController
- ConversationLabelsController
- ConversationAssignmentController
- ConversationStatusController
- ConversationParticipantsController
- ConversationSearchController
- MessageSearchController
- ConversationFiltersController
- ConversationBulkActionsController

### Contacts (8 controllers)
- ContactsController
- ContactLabelsController
- ContactMergeController
- ContactInboxesController
- ContactConversationsController
- ContactNotesController
- ContactImportController
- ContactSearchController

### Inboxes & Channels (8 controllers)
- InboxesController
- InboxMembersController
- InboxAgentsController
- ChannelsController (base)
- ChannelFacebookController
- ChannelWhatsAppController
- ChannelEmailController
- ChannelWebWidgetController

### Teams (4 controllers)
- TeamsController
- TeamMembersController
- TeamAgentsController
- TeamConversationsController

### Authentication (2 controllers)
- ConfirmationsController
- RegistrationsController

## Success Criteria
- ✅ All ~40 controllers migrated
- ✅ Request validation (DTOs) implemented
- ✅ Response serialization matches Rails
- ✅ All tests passing (≥90% coverage)
- ✅ API contract unchanged

## Parallel Strategy

**Team A**: Account, User, Agent (10 controllers) - 1.5 weeks
**Team B**: Conversation, Message (10 controllers) - 1.5 weeks  
**Team C**: Contact, Inbox (10 controllers) - 1.5 weeks
**Team D**: Team, Auth (10 controllers) - 1.5 weeks

## Task Pattern Per Controller

### Steps (4-6 hours per controller):
1. Read Rails controller (`app/controllers/api/v1/[name]_controller.rb`)
2. Read Rails request specs
3. Write NestJS controller tests (TDD: Red)
4. Create DTOs for request validation
5. Implement controller with NestJS decorators
6. Implement response serialization
7. Run tests (TDD: Green)
8. Test with Supertest (integration)
9. Verify API contract matches Rails

### Example Controller Structure
```typescript
@Controller('api/v1/conversations')
@UseGuards(JwtAuthGuard)
export class ConversationsController {
  @Get()
  async index(@Query() query: ListConversationsDto, @CurrentUser() user: User) {
    // Implementation
  }

  @Post()
  async create(@Body() dto: CreateConversationDto, @CurrentUser() user: User) {
    // Implementation
  }

  @Get(':id')
  async show(@Param('id') id: string, @CurrentUser() user: User) {
    // Implementation
  }

  @Patch(':id')
  async update(
    @Param('id') id: string,
    @Body() dto: UpdateConversationDto,
    @CurrentUser() user: User
  ) {
    // Implementation
  }
}
```

## Critical Requirements

### Request Validation
- Use class-validator DTOs for all inputs
- Validate all query parameters
- Validate all body parameters
- Return 422 for validation errors (match Rails)

### Response Format
- Must match Rails JSON response exactly
- Use serializers/transformers
- Include pagination meta
- Include proper HTTP status codes

### Authentication
- JWT token validation on all endpoints
- Proper 401 responses
- Account/user context in requests

### Authorization
- Check permissions before actions
- Return 403 for unauthorized
- Match Rails Pundit policies

## Estimated Time
- 40 controllers × 5 hours avg = 200 hours
- With 4 engineers: 50 hours each ≈ 1.5 weeks

## Risk: High
- API contract MUST match exactly
- Breaking changes will break frontend
- Extensive integration testing required

---

**Status**: 🟡 Ready (after Epic 03-06)
**Rails Files**: `app/controllers/api/v1/*`
EOF

# Epic 08: API v1 Extended
cat > phase-3-api-layer/epic-08-api-v1-extended.md << 'EOF'
# Epic 08: API v1 Extended Endpoints

## Overview
- **Duration**: 1.5 weeks
- **Complexity**: Medium-High
- **Dependencies**: Epic 07 (core endpoints), Epic 03-06 (models)
- **Team Size**: 3 engineers
- **Can Parallelize**: Yes (by feature area)

## Scope: ~40 Extended Controllers

### Reporting & Analytics (6 controllers)
- ReportsController
- DashboardController
- ConversationMetricsController
- AgentMetricsController
- InboxMetricsController
- CsatReportsController

### Integrations (6 controllers)
- IntegrationsController
- IntegrationsHooksController
- SlackIntegrationsController
- DialogflowIntegrationsController
- GoogleIntegrationsController
- WebhooksController

### Automation & Workflows (4 controllers)
- AutomationRulesController
- MacrosController
- CannedResponsesController
- MessageTemplatesController

### Labels & Tags (3 controllers)
- LabelsController
- TagsController
- LabelAssignmentsController

### Notifications (4 controllers)
- NotificationsController
- NotificationSettingsController
- NotificationSubscriptionsController
- NotificationPreferencesController

### Custom Attributes (3 controllers)
- CustomAttributesController
- CustomAttributeDefinitionsController
- CustomFiltersController

### Help Center / Portal (6 controllers)
- PortalsController
- CategoriesController
- ArticlesController
- FoldersController
- PortalSearchController
- ArticleSearchController

### Configuration & Settings (4 controllers)
- AccountSettingsController
- UserSettingsController
- InboxSettingsController
- InstallationConfigController

### Other (4 controllers)
- AttachmentsController
- NotesController
- AvatarsController
- SearchController

## Success Criteria
- ✅ All ~40 extended controllers migrated
- ✅ Feature parity with Rails
- ✅ Tests passing (≥90%)
- ✅ API contract unchanged

## Parallel Strategy

**Team A**: Reporting, Analytics, Integrations (12 controllers) - 1.5 weeks
**Team B**: Automation, Labels, Notifications (11 controllers) - 1.5 weeks
**Team C**: Custom Attrs, Help Center, Config, Other (17 controllers) - 1.5 weeks

## Estimated Time
- 40 controllers × 5 hours = 200 hours
- With 3 engineers: ~67 hours each ≈ 1.5 weeks

---

**Status**: 🟡 Ready (after Epic 07)
**Rails Files**: `app/controllers/api/v1/*`
EOF

# Continue with more epics...
echo "Created Epic 07-08 plans"

