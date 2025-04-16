#!/bin/bash

### Chạy script sau: ./build-and-check.sh [new_version]
### Nếu không cung cấp new_version, script sẽ tự động tăng version

# Bật chế độ dừng khi có lỗi
set -e

# Các biến môi trường
USERNAME="thotran113"
APP_NAME="chatwoot-interactive"
IMAGE_NAME="$USERNAME/$APP_NAME"

# Hàm để tăng version
increment_version() {
    local version=$1
    local base_version
    local suffix=""

    # Kiểm tra xem version có hậu tố không (ví dụ: -beta)
    if [[ $version == *-* ]]; then
        base_version=${version%%-*}
        suffix=${version##*-}
        suffix="-$suffix"
    else
        base_version=$version
    fi

    local delimiter=.
    local array=($(echo "$base_version" | tr $delimiter ' '))
    array[$((${#array[@]} - 1))]=$((${array[$((${#array[@]} - 1))]} + 1))

    # Trả về version mới với hậu tố (nếu có)
    echo $(local IFS=$delimiter ; echo "${array[*]}$suffix")
}

# Hàm để lấy version hiện tại từ Docker Hub
get_latest_version() {
    # Thử lấy tags từ Docker Hub
    local tags=$(curl -s "https://hub.docker.com/v2/repositories/$USERNAME/$APP_NAME/tags/" | grep -o '"name":"[^"]*' | grep -v latest | sed 's/"name":"//g')

    if [ -z "$tags" ]; then
        echo "1.0.39-beta"  # Version mặc định nếu không tìm thấy tags
        return
    fi

    # Hiển thị tất cả các tags để debug
    echo "Tất cả các tags tìm thấy:" >&2
    echo "$tags" >&2

    # Kiểm tra xem có version 1.0.39-beta không
    if echo "$tags" | grep -q "1.0.39-beta"; then
        echo "1.0.39-beta"
        return
    fi

    # Lọc các tags là version (bao gồm cả các version có hậu tố như -beta)
    local version_tags=$(echo "$tags" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+(\-[a-zA-Z0-9]+)?$')

    if [ -z "$version_tags" ]; then
        echo "1.0.39-beta"  # Version mặc định nếu không tìm thấy version tags
        return
    fi

    # Hiển thị các version tags để debug
    echo "Các version tags tìm thấy:" >&2
    echo "$version_tags" >&2

    # Sắp xếp các version và lấy version cao nhất (chỉ xử lý các version không có hậu tố)
    local standard_versions=$(echo "$version_tags" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$')

    if [ -n "$standard_versions" ]; then
        local latest_version=$(echo "$standard_versions" | sort -t. -k1,1n -k2,2n -k3,3n | tail -n1)
        echo "$latest_version"
    else
        # Nếu không có version chuẩn, lấy version có hậu tố cao nhất
        echo "1.0.39-beta"  # Trả về version mặc định
    fi
}

# Xác định version mới
if [ -z "$1" ]; then
    # Nếu không cung cấp version mới, tự động tăng version
    CURRENT_VERSION=$(get_latest_version)
    NEW_VERSION=$(increment_version "$CURRENT_VERSION")
    echo "🔄 Tự động tăng version từ $CURRENT_VERSION lên $NEW_VERSION"
else
    NEW_VERSION=$1
    echo "📝 Sử dụng version được chỉ định: $NEW_VERSION"
fi

# Lưu version cũ để sử dụng làm cache
OLD_VERSION=$(get_latest_version)
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

# Kiểm tra xem image latest có tồn tại trong máy không
echo "🔍 Kiểm tra image latest trong máy..."
if docker image inspect "$IMAGE_NAME:latest" &> /dev/null; then
    echo "✅ Đã tìm thấy image latest trong máy"
    LATEST_EXISTS=true
else
    echo "⚠️ Không tìm thấy image latest trong máy"
    LATEST_EXISTS=false

    # Pull image latest từ Docker Hub
    echo "📥 Đang pull image latest từ Docker Hub..."
    if docker pull "$IMAGE_NAME:latest"; then
        echo "✅ Đã pull thành công image latest từ Docker Hub"
        LATEST_EXISTS=true
    else
        echo "⚠️ Không thể pull image latest từ Docker Hub, sẽ build mới hoàn toàn"
    fi
fi

# Build image với version cụ thể
echo "📦 Building image version $NEW_VERSION..."

# Xây dựng danh sách các image cache
CACHE_FROM_ARGS=""

# Nếu có image latest, sử dụng nó làm cache
if [ "$LATEST_EXISTS" = true ]; then
    CACHE_FROM_ARGS="$CACHE_FROM_ARGS --cache-from $IMAGE_NAME:latest"
    echo "🔄 Sử dụng cache từ image latest..."
fi

# Nếu có OLD_VERSION, thử pull và sử dụng nó làm cache
if [ -n "$OLD_VERSION" ]; then
    echo "🔍 Kiểm tra image version $OLD_VERSION..."

    # Kiểm tra xem image OLD_VERSION có tồn tại trong máy không
    if ! docker image inspect "$IMAGE_NAME:$OLD_VERSION" &> /dev/null; then
        echo "📥 Đang pull image version $OLD_VERSION từ Docker Hub..."
        docker pull "$IMAGE_NAME:$OLD_VERSION" || echo "⚠️ Không thể pull image version $OLD_VERSION"
    else
        echo "✅ Đã tìm thấy image version $OLD_VERSION trong máy"
    fi

    # Thêm vào danh sách cache
    if docker image inspect "$IMAGE_NAME:$OLD_VERSION" &> /dev/null; then
        CACHE_FROM_ARGS="$CACHE_FROM_ARGS --cache-from $IMAGE_NAME:$OLD_VERSION"
        echo "🔄 Sử dụng cache từ image version $OLD_VERSION..."
    fi
fi

# Build image với cache và các tham số tối ưu
echo "📦 Thực hiện build với các tham số: $BUILD_ARGS $CACHE_FROM_ARGS"
docker build $BUILD_ARGS $CACHE_FROM_ARGS -t "$IMAGE_NAME:$NEW_VERSION" -f docker/Dockerfile .
if [ $? -ne 0 ]; then
    echo "❌ Lỗi: Không thể build image"
    exit 1
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

# Lưu version mới vào file để sử dụng cho lần sau
echo "$NEW_VERSION" > .last_version
echo "💾 Đã lưu version $NEW_VERSION vào file .last_version"
