# Epic 03: Database Models & Migrations

## Overview

**Duration**: 3-4 weeks
**Complexity**: Very High
**Team Size**: 3-4 engineers (can parallelize)
**Dependencies**: Epic 01 (Infrastructure), Epic 02 (Testing)
**Can Run Parallel**: Yes (split by model groups)

## Scope

This epic migrates all 58 ActiveRecord models to TypeORM entities, including associations, validations, scopes, and migrations.

**Includes:**
- 58 TypeORM entities
- Model associations (226 total)
- Validations
- Scopes/query methods
- Instance methods
- Class methods
- Hooks (before/after callbacks)
- Database migrations
- Seed data
- Full test coverage for each model

**Excludes:**
- Controllers (Epic 04)
- Services (Epic 04)
- Business logic (stays in services)

## Success Criteria

- ✅ All 58 models migrated with 100% feature parity
- ✅ All 226 associations working
- ✅ All validations ported
- ✅ All tests passing (≥90% coverage)
- ✅ Migrations run successfully
- ✅ Seed data loads
- ✅ No N+1 queries
- ✅ Database indexes created

## Estimated Size

- **58 model files**
- **58 test files**
- **~30 migration files**
- **~200 hours** of engineering work
- **~20 hours** of testing

---

## Sub-Epic Breakdown

### Sub-Epic 3.1: Core Models (8 models, 2 weeks)

**Models:**
1. Account (multi-tenancy root)
2. User (authentication, roles)
3. Team (agent teams)
4. TeamMember (join table)
5. Inbox (communication channels)
6. Conversation (message threads)
7. Message (conversation messages)
8. Contact (customers)

**Priority**: HIGHEST (everything depends on these)

**Parallel Opportunities**:
- Team A: Account, User, Team
- Team B: Inbox, Conversation, Message
- Team C: Contact

**Detailed Tasks**: See `core-models.md`

---

### Sub-Epic 3.2: Channel Models (9 models, 1 week)

**Models:**
1. Channel::FacebookPage
2. Channel::TwitterProfile
3. Channel::TwilioSms
4. Channel::Email
5. Channel::WebWidget
6. Channel::Api
7. Channel::Telegram
8. Channel::Line
9. Channel::Whatsapp

**Priority**: HIGH (required for integrations)

**Dependencies**: Inbox model (from 3.1)

**Parallel Opportunities**: Each channel can be done independently

**Detailed Tasks**: See `channel-models.md`

---

### Sub-Epic 3.3: Integration Models (10 models, 1 week)

**Models:**
1. Integrations::Hook (webhooks)
2. Integrations::Slack
3. Integrations::Dialogflow
4. Integrations::Google
5. Integrations::Shopify
6. AgentBot
7. AgentBotInbox
8. WorkingHour
9. Webhook
10. ApplicationHook

**Priority**: MEDIUM

**Dependencies**: Account, Inbox

**Detailed Tasks**: See `integration-models.md`

---

### Sub-Epic 3.4: Supporting Models (31 models, 1-2 weeks)

**Categories:**

**Messaging & Content:**
- Attachment
- Note
- CannedResponse
- MessageTemplate

**Automation:**
- AutomationRule
- Macro

**Analytics & Reporting:**
- ReportingEvent
- ConversationSummary
- CsatSurvey
- CsatSurveyResponse

**Help Center:**
- Portal
- Category
- Article
- Folder

**Custom Fields:**
- CustomAttribute
- CustomAttributeDefinition
- CustomFilter

**Labels & Tags:**
- Label
- ConversationLabel (join table)

**Notifications:**
- Notification
- NotificationSetting
- NotificationSubscription

**Platform & API:**
- Platform::App
- Platform::AppKey
- AccessToken
- ApiKeyInbox

**Other:**
- Avatar
- DataImport
- Contact::Inbox (join table)
- InstallationConfig

**Priority**: MEDIUM to LOW

**Parallel Opportunities**: High (most are independent)

**Detailed Tasks**: See `supporting-models.md`

---

## Common Pattern for Each Model

### Step 1: Read Original Rails Model

```bash
cat app/models/user.rb
cat spec/models/user_spec.rb
```

### Step 2: Write Tests First (TDD)

```typescript
// src/models/user.entity.spec.ts
describe('User Entity', () => {
  describe('validations', () => {
    it('requires email', async () => { ... });
    it('requires unique email', async () => { ... });
    // ... more validation tests
  });

  describe('associations', () => {
    it('belongs to account', async () => { ... });
    it('has many conversations', async () => { ... });
  });

  describe('methods', () => {
    it('generates JWT token', async () => { ... });
  });
});
```

### Step 3: Implement TypeORM Entity

```typescript
// src/models/user.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, OneToMany } from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  email: string;

  @Column()
  name: string;

  @ManyToOne(() => Account, account => account.users)
  account: Account;

  @OneToMany(() => Conversation, conversation => conversation.assignee)
  conversations: Conversation[];

  // ... more fields, associations, methods
}
```

### Step 4: Create Migration

```bash
pnpm migration:generate src/database/migrations/CreateUsers
```

### Step 5: Run Tests

```bash
pnpm test src/models/user.entity.spec.ts
```

### Step 6: Verify Feature Parity

- ✅ All fields present
- ✅ All associations work
- ✅ All validations active
- ✅ All methods ported
- ✅ Tests pass
- ✅ Migration runs

---

## Model Migration Checklist (Per Model)

### Fields
- ⬜ All columns mapped
- ⬜ Correct data types
- ⬜ Nullable handled
- ⬜ Default values set
- ⬜ Unique constraints
- ⬜ Indexes created

### Associations
- ⬜ belongs_to → @ManyToOne
- ⬜ has_many → @OneToMany
- ⬜ has_one → @OneToOne
- ⬜ has_and_belongs_to_many → @ManyToMany
- ⬜ Polymorphic associations handled
- ⬜ Through associations work
- ⬜ Inverse relationships set

### Validations
- ⬜ validates_presence_of → @Column({ nullable: false })
- ⬜ validates_uniqueness_of → @Column({ unique: true })
- ⬜ validates_length_of → custom validator
- ⬜ validates_format_of → custom validator
- ⬜ Custom validations ported
- ⬜ Validation messages match

### Scopes & Queries
- ⬜ default_scope → TypeORM equivalent
- ⬜ Named scopes → Repository methods
- ⬜ Query methods → Repository methods

### Methods
- ⬜ Instance methods ported
- ⬜ Class methods ported
- ⬜ Method signatures match

### Hooks (Callbacks)
- ⬜ before_save → @BeforeInsert / @BeforeUpdate
- ⬜ after_create → @AfterInsert
- ⬜ before_destroy → @BeforeRemove
- ⬜ after_update → @AfterUpdate

### Tests
- ⬜ Factory created
- ⬜ Validation tests written
- ⬜ Association tests written
- ⬜ Method tests written
- ⬜ All tests passing
- ⬜ Coverage ≥90%

---

## Database Migration Strategy

### Approach: Schema Compatibility

**We're NOT migrating data** - TypeScript will use the existing PostgreSQL database that Rails uses.

**Requirements:**
- TypeORM entities must match existing schema exactly
- Column names must match Rails conventions (snake_case)
- Table names must match Rails conventions (plural)
- Foreign keys must match
- Indexes must match

**Configuration:**

```typescript
// TypeORM naming strategy
import { DefaultNamingStrategy, NamingStrategyInterface } from 'typeorm';
import { snakeCase } from 'typeorm/util/StringUtils';

export class RailsNamingStrategy extends DefaultNamingStrategy implements NamingStrategyInterface {
  tableName(className: string, customName: string): string {
    return customName ? customName : pluralize(snakeCase(className));
  }

  columnName(propertyName: string, customName: string, embeddedPrefixes: string[]): string {
    return customName ? customName : snakeCase(propertyName);
  }

  relationName(propertyName: string): string {
    return snakeCase(propertyName);
  }

  joinColumnName(relationName: string, referencedColumnName: string): string {
    return snakeCase(relationName + '_' + referencedColumnName);
  }

  joinTableName(firstTableName: string, secondTableName: string): string {
    return snakeCase(firstTableName + '_' + secondTableName);
  }
}
```

### Migration Process

1. **Inspect existing Rails schema**
   ```bash
   cat db/schema.rb
   ```

2. **Create matching TypeORM entity**
   - Use `@Column({ name: 'snake_case_name' })` to match Rails
   - Use `@Table({ name: 'plural_table_name' })`

3. **Generate migration (for verification)**
   ```bash
   pnpm migration:generate src/database/migrations/VerifyUser
   ```

4. **Compare migration with existing schema**
   - Should be NO differences
   - If differences exist, fix entity definition

5. **Do NOT run migrations on production** (schema already exists)

---

## Association Patterns

### Rails → TypeORM Equivalents

**belongs_to:**
```ruby
# Rails
belongs_to :account
```
```typescript
// TypeORM
@ManyToOne(() => Account, account => account.users)
@JoinColumn({ name: 'account_id' })
account: Account;

@Column({ name: 'account_id' })
accountId: string;
```

**has_many:**
```ruby
# Rails
has_many :conversations
```
```typescript
// TypeORM
@OneToMany(() => Conversation, conversation => conversation.assignee)
conversations: Conversation[];
```

**has_one:**
```ruby
# Rails
has_one :profile
```
```typescript
// TypeORM
@OneToOne(() => Profile, profile => profile.user)
profile: Profile;
```

**has_and_belongs_to_many:**
```ruby
# Rails
has_and_belongs_to_many :teams
```
```typescript
// TypeORM
@ManyToMany(() => Team, team => team.members)
@JoinTable({ name: 'team_members' })
teams: Team[];
```

**Polymorphic:**
```ruby
# Rails
belongs_to :attachable, polymorphic: true
```
```typescript
// TypeORM (manual handling required)
@Column({ name: 'attachable_type' })
attachableType: string;

@Column({ name: 'attachable_id' })
attachableId: string;

// Helper method
async getAttachable(): Promise<Message | Conversation> {
  if (this.attachableType === 'Message') {
    return messageRepository.findOne(this.attachableId);
  }
  // ... handle other types
}
```

---

## Validation Patterns

### Rails → TypeORM Equivalents

**Presence:**
```ruby
# Rails
validates :email, presence: true
```
```typescript
// TypeORM
import { IsNotEmpty } from 'class-validator';

@Column()
@IsNotEmpty()
email: string;
```

**Uniqueness:**
```ruby
# Rails
validates :email, uniqueness: true
```
```typescript
// TypeORM
@Column({ unique: true })
email: string;

// + custom validator for scoped uniqueness
```

**Format:**
```ruby
# Rails
validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
```
```typescript
// TypeORM
import { IsEmail } from 'class-validator';

@Column()
@IsEmail()
email: string;
```

**Length:**
```ruby
# Rails
validates :name, length: { minimum: 2, maximum: 255 }
```
```typescript
// TypeORM
import { Length } from 'class-validator';

@Column({ length: 255 })
@Length(2, 255)
name: string;
```

**Custom:**
```ruby
# Rails
validate :custom_validation_method
```
```typescript
// TypeORM
import { ValidatorConstraint, ValidatorConstraintInterface, Validate } from 'class-validator';

@ValidatorConstraint({ name: 'customValidation', async: false })
class CustomValidation implements ValidatorConstraintInterface {
  validate(value: any, args: ValidationArguments) {
    // Custom logic
    return true;
  }
}

@Column()
@Validate(CustomValidation)
field: string;
```

---

## Performance Considerations

### Avoiding N+1 Queries

**Rails uses `includes()` / `joins()`:**
```ruby
# Rails
User.includes(:account, :conversations).all
```

**TypeORM uses `relations` or `leftJoinAndSelect`:**
```typescript
// TypeORM - Option 1: relations
const users = await userRepository.find({
  relations: ['account', 'conversations'],
});

// TypeORM - Option 2: Query Builder
const users = await userRepository
  .createQueryBuilder('user')
  .leftJoinAndSelect('user.account', 'account')
  .leftJoinAndSelect('user.conversations', 'conversations')
  .getMany();
```

### Indexes

**All foreign keys must have indexes:**
```typescript
@Entity()
@Index(['accountId'])  // Add index
export class User {
  @Column({ name: 'account_id' })
  accountId: string;
}
```

**Composite indexes:**
```typescript
@Entity()
@Index(['accountId', 'email'], { unique: true })
export class User { }
```

---

## Testing Strategy

### Model Test Structure

```typescript
describe('User Entity', () => {
  let userRepository: Repository<User>;
  let accountFactory: AccountFactory;
  let userFactory: UserFactory;

  beforeEach(() => {
    userRepository = getTestDataSource().getRepository(User);
    accountFactory = new AccountFactory();
    userFactory = new UserFactory();
  });

  describe('validations', () => {
    it('requires email', async () => { ... });
    it('validates email format', async () => { ... });
    it('enforces unique email', async () => { ... });
    // ... all validations
  });

  describe('associations', () => {
    it('belongs to account', async () => { ... });
    it('has many conversations', async () => { ... });
    // ... all associations
  });

  describe('scopes', () => {
    it('finds active users', async () => { ... });
    // ... all scopes
  });

  describe('instance methods', () => {
    it('generates JWT token', async () => { ... });
    it('validates password', async () => { ... });
    // ... all instance methods
  });

  describe('class methods', () => {
    it('finds by email', async () => { ... });
    // ... all class methods
  });

  describe('hooks', () => {
    it('hashes password before save', async () => { ... });
    // ... all hooks
  });
});
```

---

## Progress Tracking

Track progress in `progress-tracker.md`:

```markdown
### Epic 03: Database Models (X/58 models)

**Core Models (X/8):**
- ✅ Account
- ✅ User
- 🔵 Team (in progress)
- ⬜ TeamMember
- ⬜ Inbox
- ⬜ Conversation
- ⬜ Message
- ⬜ Contact

**Channel Models (0/9):**
- ⬜ FacebookPage
- ⬜ TwitterProfile
...
```

---

## Rollback Plan

**Per model:**
- TypeORM entity doesn't affect Rails
- Can remove TypeScript model without impact
- Rails continues using ActiveRecord

**Full Epic:**
- Remove all entity files
- Remove migrations
- Remove factories
- No production impact (Rails still working)

**Time to Rollback**: < 10 minutes

---

## Dependencies

**This epic depends on:**
- ✅ Epic 01: Infrastructure (TypeORM setup)
- ✅ Epic 02: Testing (factories, test database)

**This epic enables:**
- Epic 04: API Controllers
- Epic 05: Authentication
- Epic 06: Background Jobs
- Epic 07: Integrations

---

## Documentation Checklist

- ⬜ MODELS.md (model documentation)
- ⬜ ASSOCIATIONS.md (association patterns)
- ⬜ VALIDATIONS.md (validation patterns)
- ⬜ MIGRATIONS.md (migration strategy)

---

## Notes

- **CRITICAL**: Use Rails naming conventions (snake_case, plural tables)
- **Test coverage must be ≥90%** for each model
- **Use factories for all test data**
- **Verify NO N+1 queries**
- **Index all foreign keys**

---

**Epic Status**: 🟡 Ready to Start (after Epic 02)
**Estimated Duration**: 3-4 weeks
**Next Epic**: Epic 04 - API Controllers & Routes

---

## Detailed Sub-Epic Plans

- [Sub-Epic 3.1: Core Models](./core-models.md) - Account, User, Conversation, Message, etc.
- [Sub-Epic 3.2: Channel Models](./channel-models.md) - Facebook, WhatsApp, Slack, etc.
- [Sub-Epic 3.3: Integration Models](./integration-models.md) - Webhooks, Dialogflow, etc.
- [Sub-Epic 3.4: Supporting Models](./supporting-models.md) - Labels, Notifications, etc.
