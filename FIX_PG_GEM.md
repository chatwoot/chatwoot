# Fix lỗi cài gem `pg` trên macOS

## Lỗi
```
Can't find the 'libpq-fe.h header
Unable to find PostgreSQL client library.
```

## Giải pháp

### Bước 1: Kiểm tra libpq đã cài chưa

```bash
# Tìm pg_config
find /opt/homebrew -name pg_config 2>/dev/null
# hoặc
find /usr/local -name pg_config 2>/dev/null
```

### Bước 2: Cấu hình bundle để sử dụng pg_config

```bash
# Nếu tìm thấy tại /opt/homebrew/Cellar/libpq/18.0/bin/pg_config
bundle config build.pg --with-pg-config=/opt/homebrew/Cellar/libpq/18.0/bin/pg_config

# Hoặc nếu dùng Homebrew standard path
bundle config build.pg --with-pg-config=/opt/homebrew/opt/libpq/bin/pg_config

# Hoặc tự động detect
PG_CONFIG_PATH=$(find /opt/homebrew -name pg_config 2>/dev/null | head -1)
bundle config build.pg --with-pg-config=$PG_CONFIG_PATH
```

### Bước 3: Cài lại bundle

```bash
bundle install
```

### Nếu chưa có libpq

```bash
# Cài libpq
brew install libpq

# Sau đó làm lại bước 2 và 3
```

## Kiểm tra cấu hình

```bash
# Xem bundle config
bundle config

# Hoặc chỉ xem config cho pg
bundle config build.pg
```

## Lưu ý

- Cấu hình này sẽ được lưu trong `.bundle/config` và áp dụng cho mọi lần `bundle install` sau này
- Nếu upgrade libpq, có thể cần cập nhật lại path
