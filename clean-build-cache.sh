#!/bin/bash

### Script để dọn dẹp build cache khi cần thiết
### Chạy script: ./clean-build-cache.sh

# Bật chế độ dừng khi có lỗi
set -e

# Các biến môi trường
USERNAME="thotran113"
APP_NAME="chatwoot-interactive"
IMAGE_NAME="$USERNAME/$APP_NAME"

echo "🧹 Bắt đầu dọn dẹp build cache..."

# Dọn dẹp Docker BuildKit cache
echo "🗑️ Dọn dẹp Docker BuildKit cache..."
docker buildx prune -f

# Dọn dẹp Docker system cache
echo "🗑️ Dọn dẹp Docker system cache..."
docker system prune -f

# Dọn dẹp registry cache image nếu tồn tại
echo "🗑️ Kiểm tra và xóa registry cache image..."
if docker image inspect "$IMAGE_NAME:cache" &> /dev/null; then
    echo "🗑️ Xóa cache image cũ..."
    docker rmi "$IMAGE_NAME:cache" || echo "⚠️ Không thể xóa cache image"
fi

# Dọn dẹp các image không sử dụng
echo "🗑️ Dọn dẹp các image không sử dụng..."
docker image prune -f

# Hiển thị thông tin disk usage sau khi dọn dẹp
echo "📊 Thông tin disk usage sau khi dọn dẹp:"
docker system df

echo "✅ Hoàn thành dọn dẹp build cache!"
echo "💡 Lần build tiếp theo sẽ mất thời gian lâu hơn do phải rebuild cache"
