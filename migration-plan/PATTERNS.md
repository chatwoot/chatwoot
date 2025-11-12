# Common Migration Patterns

Quick reference for migrating Rails patterns to TypeScript/NestJS.

---

## Model Patterns

### Pattern 1: Basic Model

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
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  @IsNotEmpty()
  @IsEmail()
  email: string;

  @Column()
  @IsNotEmpty()
  name: string;
}
```

---

### Pattern 2: Associations

**Rails:**
```ruby
class User < ApplicationRecord
  belongs_to :account
  has_many :conversations
  has_one :profile
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

  @OneToOne(() => Profile, profile => profile.user)
  profile: Profile;
}
```

---

### Pattern 3: Scopes

**Rails:**
```ruby
class User < ApplicationRecord
  scope :active, -> { where(status: 'active') }
  scope :by_role, ->(role) { where(role: role) }
end
```

**TypeScript:**
```typescript
// In UserRepository or Service
export class UserRepository extends Repository<User> {
  findActive(): Promise<User[]> {
    return this.find({ where: { status: 'active' } });
  }

  findByRole(role: string): Promise<User[]> {
    return this.find({ where: { role } });
  }
}
```

---

### Pattern 4: Callbacks/Hooks

**Rails:**
```ruby
class User < ApplicationRecord
  before_save :normalize_email
  after_create :send_welcome_email
  
  private
  
  def normalize_email
    self.email = email.downcase.strip
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
    this.email = this.email.toLowerCase().trim();
  }

  @AfterInsert()
  async sendWelcomeEmail() {
    // Emit event or call service
    await emailService.sendWelcome(this.email);
  }
}
```

---

## Controller Patterns

### Pattern 5: Basic Controller

**Rails:**
```ruby
class Api::V1::UsersController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @users = current_user.account.users
    render json: @users
  end
  
  def create
    @user = User.create!(user_params)
    render json: @user, status: :created
  end
  
  private
  
  def user_params
    params.require(:user).permit(:email, :name)
  end
end
```

**TypeScript:**
```typescript
@Controller('api/v1/users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private userService: UserService) {}

  @Get()
  async index(@CurrentUser() user: User) {
    const users = await this.userService.findByAccount(user.accountId);
    return { data: users };
  }

  @Post()
  async create(@Body() dto: CreateUserDto, @CurrentUser() user: User) {
    const newUser = await this.userService.create(dto, user.accountId);
    return newUser;
  }
}

// DTO
export class CreateUserDto {
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @IsNotEmpty()
  name: string;
}
```

---

### Pattern 6: Nested Routes

**Rails:**
```ruby
# routes.rb
resources :conversations do
  resources :messages
end

# Controller
class Api::V1::MessagesController < ApplicationController
  def index
    @conversation = Conversation.find(params[:conversation_id])
    @messages = @conversation.messages
    render json: @messages
  end
end
```

**TypeScript:**
```typescript
@Controller('api/v1/conversations/:conversationId/messages')
export class MessagesController {
  @Get()
  async index(@Param('conversationId') conversationId: string) {
    const messages = await this.messageService.findByConversation(conversationId);
    return { data: messages };
  }
}
```

---

## Service Patterns

### Pattern 7: Service Object

**Rails:**
```ruby
class Messages::CreateService
  def initialize(conversation:, content:, user:)
    @conversation = conversation
    @content = content
    @user = user
  end
  
  def perform
    Message.create!(
      conversation: @conversation,
      content: @content,
      sender: @user
    )
  end
end
```

**TypeScript:**
```typescript
@Injectable()
export class MessageService {
  constructor(
    @InjectRepository(Message)
    private messageRepository: Repository<Message>,
  ) {}

  async create(conversationId: string, content: string, userId: string): Promise<Message> {
    const message = this.messageRepository.create({
      conversationId,
      content,
      senderId: userId,
    });
    return this.messageRepository.save(message);
  }
}
```

---

## Background Job Patterns

### Pattern 8: Background Job

**Rails:**
```ruby
class SendEmailJob < ApplicationJob
  queue_as :default
  
  def perform(user_id, email_type)
    user = User.find(user_id)
    UserMailer.send(email_type, user).deliver_now
  end
end

# Usage
SendEmailJob.perform_later(user.id, 'welcome')
```

**TypeScript:**
```typescript
@Processor('email')
export class EmailProcessor {
  @Process('send')
  async handleSend(job: Job<{ userId: string; emailType: string }>) {
    const { userId, emailType } = job.data;
    const user = await this.userRepository.findOne(userId);
    await this.emailService.send(emailType, user);
  }
}

// Usage
await this.emailQueue.add('send', {
  userId: user.id,
  emailType: 'welcome',
});
```

---

## Testing Patterns

### Pattern 9: Model Tests

**Rails (RSpec):**
```ruby
RSpec.describe User, type: :model do
  describe 'validations' do
    it 'requires email' do
      user = User.new(email: nil)
      expect(user.valid?).to be false
    end
  end
  
  describe 'associations' do
    it { should belong_to(:account) }
    it { should have_many(:conversations) }
  end
end
```

**TypeScript (Vitest):**
```typescript
describe('User Entity', () => {
  describe('validations', () => {
    it('requires email', async () => {
      const user = UserFactory.build({ email: '' });
      await expect(user.save()).rejects.toThrow();
    });
  });

  describe('associations', () => {
    it('belongs to account', async () => {
      const user = await UserFactory.create();
      expect(user.account).toBeDefined();
    });

    it('has many conversations', async () => {
      const user = await UserFactory.create();
      const conversations = await user.conversations;
      expect(conversations).toBeInstanceOf(Array);
    });
  });
});
```

---

### Pattern 10: Controller Tests

**Rails (RSpec):**
```ruby
RSpec.describe Api::V1::UsersController, type: :request do
  describe 'GET /api/v1/users' do
    it 'returns users' do
      user = create(:user)
      get '/api/v1/users', headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_an(Array)
    end
  end
end
```

**TypeScript (Vitest + Supertest):**
```typescript
describe('UsersController (HTTP)', () => {
  let app: INestApplication;
  let authToken: string;

  beforeAll(async () => {
    app = await createTestApp();
    const user = await UserFactory.create();
    authToken = user.generateToken();
  });

  describe('GET /api/v1/users', () => {
    it('returns users', async () => {
      const response = await request(app.getHttpServer())
        .get('/api/v1/users')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data).toBeInstanceOf(Array);
    });
  });
});
```

---

## Query Patterns

### Pattern 11: Complex Queries

**Rails:**
```ruby
User.joins(:conversations)
    .where(conversations: { status: 'open' })
    .where('users.created_at > ?', 1.month.ago)
    .order(created_at: :desc)
    .limit(10)
```

**TypeScript:**
```typescript
const users = await userRepository
  .createQueryBuilder('user')
  .innerJoin('user.conversations', 'conversation')
  .where('conversation.status = :status', { status: 'open' })
  .andWhere('user.created_at > :date', { date: oneMonthAgo })
  .orderBy('user.created_at', 'DESC')
  .limit(10)
  .getMany();
```

---

## Additional Patterns

See also:
- [GLOSSARY.md](./GLOSSARY.md) - Terminology mapping
- [TESTING-GUIDE.md](./TESTING-GUIDE.md) - Testing patterns
- [RAILS-VS-TYPESCRIPT.md](./RAILS-VS-TYPESCRIPT.md) - Side-by-side comparisons

