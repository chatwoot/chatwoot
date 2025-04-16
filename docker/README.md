# Tối ưu hiệu năng build Docker image

## Các cải tiến đã thực hiện

### 1. Tối ưu Dockerfile

File `Dockerfile.optimized` đã được tạo với các cải tiến sau:

- **Tối ưu layer caching**: Sắp xếp lại các lệnh để tận dụng tối đa Docker layer caching
- **Tách riêng việc cài đặt dependencies**: Copy và cài đặt dependencies trước khi copy toàn bộ code
- **Sử dụng `--frozen-lockfile` với pnpm**: Tăng tốc cài đặt Node.js packages
- **Tối ưu hóa cài đặt Ruby gems**: Sử dụng `-j 4` để tận dụng đa nhân
- **Giảm kích thước image**: Xóa các file không cần thiết sau khi build

### 2. Tối ưu script build

File `build-and-push-optimized.sh` đã được tạo với các cải tiến sau:

- **Kích hoạt BuildKit**: Sử dụng `DOCKER_BUILDKIT=1` để tăng tốc quá trình build
- **Sử dụng inline cache**: Thêm `--build-arg BUILDKIT_INLINE_CACHE=1` để tạo inline cache
- **Pull image cũ trước khi build**: Đảm bảo cache từ xa được sử dụng hiệu quả
- **Thêm log thời gian build**: Giúp theo dõi hiệu năng build

### 3. Tối ưu .dockerignore

File `.dockerignore` đã được cập nhật để loại bỏ các file không cần thiết trong quá trình build, giúp giảm context size và tăng tốc quá trình build.

## Cách sử dụng

### Sử dụng Dockerfile tối ưu

```bash
# Build với Dockerfile tối ưu
docker build -t chatwoot:optimized -f docker/Dockerfile.optimized .

# Hoặc sử dụng script build tối ưu
./build-and-push-optimized.sh 1.0.1 1.0.0
```

### So sánh hiệu năng

Để so sánh hiệu năng giữa Dockerfile gốc và Dockerfile tối ưu:

```bash
# Build với Dockerfile gốc
time docker build -t chatwoot:original -f docker/Dockerfile .

# Build với Dockerfile tối ưu
time docker build -t chatwoot:optimized -f docker/Dockerfile.optimized .
```

## Các cải tiến tiềm năng khác

1. **Sử dụng Docker Registry để lưu trữ cache**: Cấu hình Docker Registry để lưu trữ và sử dụng cache giữa các lần build
2. **Sử dụng multi-stage build song song**: Khi BuildKit hỗ trợ đầy đủ, có thể thực hiện các stage song song
3. **Tối ưu hóa cài đặt dependencies**: Xem xét sử dụng các công cụ như `bundle-diff` để chỉ cài đặt các gems đã thay đổi
4. **Sử dụng Docker layer caching trong CI/CD**: Cấu hình CI/CD để tận dụng Docker layer caching
