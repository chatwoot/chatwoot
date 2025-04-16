#!/bin/bash

### Chạy script sau: ./build-and-push-optimized.sh <new_version> [old_version]
### Ví dụ: ./build-and-push-optimized.sh 1.0.1 1.0.0

# Bật chế độ dừng khi có lỗi
set -e

# Kiểm tra xem có truyền version mới vào không
if [ -z "$1" ]
then
    echo "Error: Version mới không được để trống"
    echo "Cách sử dụng: ./build-and-push-optimized.sh <new_version> [old_version]"
    echo "Ví dụ: ./build-and-push-optimized.sh 1.0.1 1.0.0"
    exit 1
fi

# Các biến môi trường
USERNAME="thotran113"
APP_NAME="chatwoot-interactive"
NEW_VERSION=$1
OLD_VERSION=$2
IMAGE_NAME="$USERNAME/$APP_NAME"

echo "🚀 Bắt đầu build và push Docker image..."
echo "Username: $USERNAME"
echo "App: $APP_NAME"
echo "New Version: $NEW_VERSION"
echo "Old Version: ${OLD_VERSION:-None}"

# Kích hoạt BuildKit để tăng tốc quá trình build
export DOCKER_BUILDKIT=1

# Thêm các tham số build để tối ưu hiệu năng
BUILD_ARGS="--build-arg BUILDKIT_INLINE_CACHE=1"

# Build image với version cụ thể
echo "📦 Building image version $NEW_VERSION..."
if [ -n "$OLD_VERSION" ]; then
    echo "🔄 Sử dụng cache từ version $OLD_VERSION..."
    
    # Pull image cũ để sử dụng cache
    docker pull "$IMAGE_NAME:$OLD_VERSION" || echo "⚠️ Không thể pull image cũ, tiếp tục build mà không có cache từ xa"
    
    # Sử dụng cache từ image cũ và thêm các tham số tối ưu
    docker build $BUILD_ARGS --cache-from "$IMAGE_NAME:$OLD_VERSION" -t "$IMAGE_NAME:$NEW_VERSION" -f docker/Dockerfile .
    if [ $? -ne 0 ]; then
        echo "❌ Lỗi: Không thể build image với cache từ version $OLD_VERSION"
        exit 1
    fi
else
    # Build mới với các tham số tối ưu
    docker build $BUILD_ARGS -t "$IMAGE_NAME:$NEW_VERSION" -f docker/Dockerfile .
    if [ $? -ne 0 ]; then
        echo "❌ Lỗi: Không thể build image"
        exit 1
    fi
fi

# Tag image version thành latest
echo "🏷️ Tagging image as latest..."
docker tag "$IMAGE_NAME:$NEW_VERSION" "$IMAGE_NAME:latest"
if [ $? -ne 0 ]; then
    echo "❌ Lỗi: Không thể tag image thành latest"
    exit 1
fi

# Push cả 2 version
echo "⬆️ Pushing image version $NEW_VERSION..."
docker push "$IMAGE_NAME:$NEW_VERSION"
if [ $? -ne 0 ]; then
    echo "❌ Lỗi: Không thể push image version $NEW_VERSION"
    exit 1
fi

echo "⬆️ Pushing image latest..."
docker push "$IMAGE_NAME:latest"
if [ $? -ne 0 ]; then
    echo "❌ Lỗi: Không thể push image latest"
    exit 1
fi

echo "✅ Hoàn thành! Images đã được push lên Docker Hub:"
echo "- $IMAGE_NAME:$NEW_VERSION"
echo "- $IMAGE_NAME:latest"

echo "📊 Thời gian build: $(date)"
