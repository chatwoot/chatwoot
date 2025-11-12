# Epic 07: API v1 Core Endpoints

## Overview
- **Duration**: 1.5 weeks
- **Complexity**: High
- **Dependencies**: Epic 03-06 (all models)
- **Team Size**: 3-4 engineers
- **Can Parallelize**: Yes (by controller group)

## Scope: ~40 Core Controllers

### Account & User Management (8 controllers)
- AccountsController - Account CRUD operations
- UsersController - User management
- ProfilesController - User profile updates
- AgentsController - Agent management
- AgentBotsController - Bot configuration
- TeamMembersController - Agent assignments
- PasswordsController - Password reset
- SessionsController - Login/logout

### Conversations & Messages (10 controllers)
- ConversationsController - Conversation CRUD
- MessagesController - Message send/receive
- ConversationLabelsController - Label management
- ConversationAssignmentController - Agent assignment
- ConversationStatusController - Status updates
- ConversationParticipantsController - Participants
- ConversationSearchController - Search
- MessageSearchController - Message search
- ConversationFiltersController - Custom filters
- ConversationBulkActionsController - Bulk operations

### Contacts (8 controllers)
- ContactsController - Contact CRUD
- ContactLabelsController - Contact labels
- ContactMergeController - Merge duplicates
- ContactInboxesController - Contact-inbox associations
- ContactConversationsController - Contact conversations
- ContactNotesController - Internal notes
- ContactImportController - Bulk import
- ContactSearchController - Contact search

### Inboxes & Channels (8 controllers)
- InboxesController - Inbox CRUD
- InboxMembersController - Inbox agents
- InboxAgentsController - Agent permissions
- ChannelsController - Channel base operations
- ChannelFacebookController - Facebook config
- ChannelWhatsAppController - WhatsApp config
- ChannelEmailController - Email config
- ChannelWebWidgetController - Widget config

### Teams (4 controllers)
- TeamsController - Team CRUD
- TeamMembersController - Team membership
- TeamAgentsController - Team agent management
- TeamConversationsController - Team conversations

### Authentication (2 controllers)
- ConfirmationsController - Email confirmation
- RegistrationsController - User registration

## Success Criteria
- ✅ All ~40 controllers migrated to NestJS
- ✅ Request validation (DTOs) implemented with class-validator
- ✅ Response serialization matches Rails exactly
- ✅ All tests passing (≥90% coverage)
- ✅ API contract unchanged (no breaking changes)
- ✅ Integration tests with Supertest pass

## Parallel Strategy

**Team A**: Account, User, Agent controllers (10 controllers) - 1.5 weeks
**Team B**: Conversation, Message controllers (10 controllers) - 1.5 weeks
**Team C**: Contact, Inbox controllers (10 controllers) - 1.5 weeks
**Team D**: Team, Auth controllers (10 controllers) - 1.5 weeks

## Task Pattern Per Controller

### Steps (4-6 hours per controller):
1. **Read Rails code**: `app/controllers/api/v1/[name]_controller.rb`
2. **Read tests**: `spec/requests/api/v1/[name]_spec.rb`
3. **Write DTO classes** for request validation
4. **Write tests first** (TDD: Red)
5. **Create NestJS controller**
6. **Implement endpoints**
7. **Add response serializers**
8. **Run tests** (TDD: Green)
9. **Integration test** with Supertest
10. **Verify API contract** matches Rails

### Example Controller
```typescript
@Controller('api/v1/conversations')
@UseGuards(JwtAuthGuard)
@ApiTags('conversations')
export class ConversationsController {
  constructor(private conversationService: ConversationService) {}

  @Get()
  @ApiOperation({ summary: 'List conversations' })
  async index(
    @Query() query: ListConversationsDto,
    @CurrentUser() user: User,
  ) {
    const conversations = await this.conversationService.findAll({
      accountId: user.accountId,
      ...query,
    });
    return {
      data: conversations.map(c => ConversationSerializer.serialize(c)),
      meta: { /* pagination */ },
    };
  }

  @Post()
  @ApiOperation({ summary: 'Create conversation' })
  async create(
    @Body() dto: CreateConversationDto,
    @CurrentUser() user: User,
  ) {
    const conversation = await this.conversationService.create(dto, user);
    return ConversationSerializer.serialize(conversation);
  }

  @Get(':id')
  async show(@Param('id') id: string, @CurrentUser() user: User) {
    const conversation = await this.conversationService.findOne(id, user);
    return ConversationSerializer.serialize(conversation);
  }

  @Patch(':id')
  async update(
    @Param('id') id: string,
    @Body() dto: UpdateConversationDto,
    @CurrentUser() user: User,
  ) {
    const conversation = await this.conversationService.update(id, dto, user);
    return ConversationSerializer.serialize(conversation);
  }
}
```

### Example DTO
```typescript
export class CreateConversationDto {
  @IsUUID()
  @IsNotEmpty()
  inboxId: string;

  @IsUUID()
  @IsNotEmpty()
  contactId: string;

  @IsString()
  @IsOptional()
  status?: string;

  @IsUUID()
  @IsOptional()
  assigneeId?: string;
}
```

### Example Serializer
```typescript
export class ConversationSerializer {
  static serialize(conversation: Conversation) {
    return {
      id: conversation.id,
      display_id: conversation.displayId,
      inbox_id: conversation.inboxId,
      contact_id: conversation.contactId,
      status: conversation.status,
      assignee_id: conversation.assigneeId,
      messages_count: conversation.messagesCount,
      created_at: conversation.createdAt,
      updated_at: conversation.updatedAt,
      // ... match Rails format exactly
    };
  }
}
```

## Critical Requirements

### 1. Request Validation
- ✅ Use class-validator DTOs for ALL inputs
- ✅ Validate query parameters
- ✅ Validate body parameters
- ✅ Validate path parameters
- ✅ Return 422 for validation errors (match Rails)
- ✅ Error messages must match Rails format

### 2. Response Format
- ✅ JSON response must match Rails EXACTLY
- ✅ Use snake_case for keys (not camelCase)
- ✅ Include pagination meta when applicable
- ✅ Proper HTTP status codes (200, 201, 204, 404, 422, etc.)
- ✅ Error responses match Rails format

### 3. Authentication
- ✅ JWT token validation on all endpoints
- ✅ Return 401 for missing/invalid token
- ✅ Extract user from token
- ✅ Account context in all requests

### 4. Authorization
- ✅ Check permissions before actions
- ✅ Return 403 for unauthorized actions
- ✅ Match Rails Pundit policies exactly

### 5. Pagination
- ✅ Support `page` and `per_page` query params
- ✅ Return pagination meta: `{ current_page, total_pages, total_count }`
- ✅ Default page size matches Rails

## Estimated Time
- 40 controllers × 5 hours avg = 200 hours
- With 4 engineers: 50 hours each ≈ **1.5 weeks**

## Risk Assessment

**Risk Level**: 🔴 **Very High**

**Why:**
- API contract MUST match Rails exactly
- Any breaking change breaks the frontend
- High integration surface area

**Mitigation:**
- Contract testing for all endpoints
- Integration tests with actual HTTP requests
- Side-by-side comparison Rails vs TypeScript responses
- Gradual rollout with feature flags
- Extensive manual testing

## Dependencies

**Must Complete First:**
- Epic 03-06 (all models available)

**Enables:**
- Epic 20 (Frontend API client can be updated)
- Epic 11 (Auth system can use these controllers)

## Rollback Plan

- Feature flag to route API requests to Rails
- Instant rollback capability
- No database changes needed

---

**Status**: 🟡 Ready (after Epic 03-06)
**Priority**: Critical (frontend depends on this)
**Rails Files**: `app/controllers/api/v1/*_controller.rb`
**Test Files**: `spec/requests/api/v1/*_spec.rb`
