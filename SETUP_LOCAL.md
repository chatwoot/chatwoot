# Hướng dẫn chạy Chatwoot Local (Không Docker)

Cách nhẹ nhất để chạy Chatwoot development mà không cần build Docker image.

## Yêu cầu

- Ruby 3.4.4 (dùng rbenv hoặc rvm)
- Node.js 24+ và pnpm
- PostgreSQL 16+ (có thể dùng Docker)
- Redis (có thể dùng Docker)
- Overmind (để chạy nhiều processes)

### Cài đặt dependencies trên macOS

```bash
# Cài PostgreSQL client library (bắt buộc cho gem pg)
brew install libpq

# Link libpq để Ruby có thể tìm thấy
brew link --force libpq

# Hoặc nếu link không được, thêm vào PATH
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/libpq/lib"
export CPPFLAGS="-I/opt/homebrew/opt/libpq/include"
```

## Setup

### 1. Cài đặt dependencies

```bash
# Cài Ruby (nếu chưa có)
rbenv install 3.4.4
rbenv local 3.4.4

# Cài Node.js và pnpm
npm install -g pnpm

# Cài Overmind (macOS)
brew install overmind

# Hoặc dùng gem
gem install overmind
```

### 2. Setup project

```bash
# Clone repo và vào thư mục
cd chatwoot

# Cài đặt Ruby dependencies
bundle install

# Cài đặt Node dependencies
pnpm install
```

### 3. Chạy PostgreSQL và Redis (Docker - nhẹ nhất)

```bash
# Chỉ chạy DB services
docker-compose -f docker-compose.local.yml up -d

# Kiểm tra services đang chạy
docker-compose -f docker-compose.local.yml ps
```

### 4. Setup database

```bash
# Tạo và migrate database
make db

# Hoặc từng bước:
# bundle exec rails db:create
# bundle exec rails db:migrate
# bundle exec rails db:seed
```

### 5. Tạo file .env

```bash
# Copy từ .env.example nếu có
cp .env.example .env

# Hoặc tạo file .env với các biến cần thiết:
cat > .env << EOF
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DATABASE=chatwoot_dev
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=

REDIS_URL=redis://localhost:6379

RAILS_ENV=development
SECRET_KEY_BASE=$(bundle exec rails secret)
FRONTEND_URL=http://localhost:3000
EOF
```

### 6. Chạy ứng dụng

```bash
# Chạy tất cả services (Rails, Sidekiq, Vite)
make run

# Hoặc chạy từng service riêng:

# Terminal 1: Rails server
make server
# hoặc
bundle exec rails s

# Terminal 2: Sidekiq worker
dotenv bundle exec sidekiq -C config/sidekiq.yml

# Terminal 3: Vite dev server
bin/vite dev
```

### 7. Truy cập ứng dụng

- Frontend: http://localhost:3000
- Vite Dev Server: http://localhost:3036
- Mailhog UI: http://localhost:8025

## Lợi ích của cách này

✅ **Nhẹ hơn**: Không cần build Docker image lớn  
✅ **Nhanh hơn**: Hot reload ngay lập tức  
✅ **Dễ debug**: Debug trực tiếp trong IDE  
✅ **Ít RAM**: Chỉ chạy DB services trong Docker  
✅ **Dễ phát triển**: Thay đổi code và thấy kết quả ngay

## Troubleshooting

### Lỗi cài gem `pg` (PostgreSQL adapter)

**Lỗi:** `Can't find the 'libpq-fe.h header` hoặc `Unable to find PostgreSQL client library`

**Giải pháp:**

```bash
# 1. Cài libpq
brew install libpq

# 2. Link libpq
brew link --force libpq

# 3. Cài lại bundle với đường dẫn đến pg_config
bundle config build.pg --with-pg-config=/opt/homebrew/opt/libpq/bin/pg_config
bundle install

# Hoặc nếu vẫn lỗi, thử:
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
bundle install
```

### Lỗi kết nối database
```bash
# Kiểm tra PostgreSQL đang chạy
docker-compose -f docker-compose.local.yml ps postgres

# Kiểm tra kết nối
psql -h localhost -U postgres -d chatwoot_dev
```

### Lỗi Redis
```bash
# Kiểm tra Redis đang chạy
docker-compose -f docker-compose.local.yml ps redis

# Test kết nối
redis-cli ping
```

### Lỗi port đã được sử dụng
```bash
# Tìm process đang dùng port
lsof -ti:3000 | xargs kill -9
lsof -ti:3036 | xargs kill -9
```

## Dừng services

```bash
# Dừng Rails app (Ctrl+C trong terminal)

# Dừng DB services
docker-compose -f docker-compose.local.yml down

# Xóa data (cẩn thận!)
docker-compose -f docker-compose.local.yml down -v
```
