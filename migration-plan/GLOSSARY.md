# Glossary - Rails ↔ TypeScript Migration

## A

**ActiveRecord** → **TypeORM** - ORM (Object-Relational Mapping) library
**ActionCable** → **Socket.io** - Real-time WebSocket library
**ActiveJob** → **BullMQ** - Background job processing
**ActiveStorage** → **Multer + S3** - File upload handling

## B

**belongs_to** → **@ManyToOne** - Association (child side)
**before_save** → **@BeforeInsert / @BeforeUpdate** - Lifecycle hook
**bundle** → **pnpm** - Package manager

## C

**class** → **class** (same, but with decorators)
**concern** → **Mixin / Base class** - Shared behavior
**controller** → **Controller** - HTTP request handler (NestJS)

## D

**Devise** → **Passport / Custom JWT** - Authentication
**def** → **function / method** - Method definition

## E

**enum** → **enum** - Enumeration (same concept)

## F

**FactoryBot** → **Custom factories** - Test data creation
**find_by** → **findOne()** - Query method

## G

**Gemfile** → **package.json** - Dependency manifest
**gem** → **npm package** - External library

## H

**has_many** → **@OneToMany** - Association (parent side)
**has_one** → **@OneToOne** - Association (one-to-one)
**has_and_belongs_to_many** → **@ManyToMany** - Join table association

## I

**include** → **import** - Module inclusion
**`:integer`** → **number** - Data type
**`:string`** → **string** - Data type
**`:text`** → **string** (or Text column type)
**`:boolean`** → **boolean**
**`:datetime`** → **Date**
**`:json`** → **object** or **Record<string, any>**

## M

**migration** → **migration** - Database schema change (similar)
**module** → **module / namespace** - Code organization

## P

**params** → **DTO** (Data Transfer Object) - Request parameters
**Pundit** → **CASL / Custom** - Authorization
**polymorphic** → **Manual handling** - TypeORM doesn't have built-in support

## R

**Rails.env** → **process.env.NODE_ENV** - Environment variable
**render** → **return** - Response return
**RSpec** → **Vitest** - Testing framework
**Rake** → **npm scripts** - Task runner
**respond_to** → **Content negotiation** (handled by NestJS)

## S

**scope** → **Repository method / Query builder** - Named query
**Sidekiq** → **BullMQ** - Background job processor
**`:symbol`** → **string** - Symbols become strings in TypeScript

## T

**t()** → **i18n.t()** - Translation helper
**`:timestamps`** → **@CreateDateColumn / @UpdateDateColumn**

## V

**validates** → **class-validator decorators** - Validation
**validates_presence_of** → **@IsNotEmpty()**
**validates_uniqueness_of** → **@Column({ unique: true })**
**validates_format_of** → **@Matches()**
**validates_length_of** → **@Length()**

## W

**where()** → **find()** or **createQueryBuilder()** - Query method

---

## Rails Conventions → TypeScript Conventions

| Rails | TypeScript |
|-------|-----------|
| snake_case (files, methods) | camelCase (methods), PascalCase (classes) |
| @instance_variable | this.instanceVariable |
| @@class_variable | static classVariable |
| CONSTANT | CONSTANT (same) |
| `app/models/user.rb` | `src/models/user.entity.ts` |
| `spec/models/user_spec.rb` | `src/models/user.entity.spec.ts` |
| `user_id` (foreign key) | userId or user_id (column name) |
| `users` (table name) | users (same) |

---

## Common Rails Patterns → TypeScript Equivalents

### Pattern 1: Model with Validations

**Rails:**
```ruby
class User < ApplicationRecord
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
end
```

**TypeScript:**
```typescript
@Entity('users')
export class User {
  @Column({ unique: true })
  @IsNotEmpty()
  @IsEmail()
  email: string;

  @Column()
  @IsNotEmpty()
  name: string;
}
```

### Pattern 2: Associations

**Rails:**
```ruby
class User < ApplicationRecord
  belongs_to :account
  has_many :conversations
end
```

**TypeScript:**
```typescript
@Entity('users')
export class User {
  @ManyToOne(() => Account, account => account.users)
  account: Account;

  @OneToMany(() => Conversation, conv => conv.user)
  conversations: Conversation[];
}
```

### Pattern 3: Scopes

**Rails:**
```ruby
class User < ApplicationRecord
  scope :active, -> { where(status: 'active') }
end
```

**TypeScript:**
```typescript
// In UserRepository
findActive(): Promise<User[]> {
  return this.find({ where: { status: 'active' } });
}
```

### Pattern 4: Callbacks

**Rails:**
```ruby
class User < ApplicationRecord
  before_save :normalize_email
  
  def normalize_email
    self.email = email.downcase
  end
end
```

**TypeScript:**
```typescript
@Entity('users')
export class User {
  @BeforeInsert()
  @BeforeUpdate()
  normalizeEmail() {
    this.email = this.email.toLowerCase();
  }
}
```

---

## Chatwoot-Specific Terms

**Account** - Multi-tenant organization (top-level entity)
**Inbox** - Communication channel configuration
**Conversation** - Chat thread between contact and agents
**Contact** - Customer/end-user
**Agent** - Team member who handles conversations
**AgentBot** - Automated assistant
**CSAT** - Customer Satisfaction Survey
**Canned Response** - Pre-defined message template
**Macro** - Automated action sequence

---

## Testing Terms

| Rails/RSpec | TypeScript/Vitest |
|-------------|-------------------|
| describe | describe (same) |
| it | it (same) |
| expect().to | expect().toBe() |
| before | beforeEach |
| let | const (in beforeEach) |
| FactoryBot.create | factory.create() |
| FactoryBot.build | factory.build() |

---

## Quick Reference: Type Mappings

| Rails Type | PostgreSQL | TypeScript | TypeORM Decorator |
|-----------|-----------|-----------|-------------------|
| integer | integer | number | @Column('int') |
| bigint | bigint | number | @Column('bigint') |
| string | varchar | string | @Column() |
| text | text | string | @Column('text') |
| boolean | boolean | boolean | @Column('boolean') |
| datetime | timestamp | Date | @Column('timestamp') |
| date | date | Date | @Column('date') |
| decimal | decimal | number | @Column('decimal') |
| float | float | number | @Column('float') |
| json | json | object | @Column('json') |
| jsonb | jsonb | object | @Column('jsonb') |
| uuid | uuid | string | @PrimaryGeneratedColumn('uuid') |
| array | array | Array | @Column('simple-array') |

---

**Need clarification?** Ask in the team channel or check the migration strategy document.
