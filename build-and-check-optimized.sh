#!/bin/bash

### Chạy script sau: ./build-and-check-optimized.sh [new_version]
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

    echo "🔍 Đang tăng version từ: $version" >&2

    # Kiểm tra xem version có hậu tố không (ví dụ: -beta)
    if [[ $version == *-* ]]; then
        base_version=${version%%-*}
        suffix=${version##*-}
        suffix="-$suffix"
        echo "📌 Phân tích: base_version=$base_version, suffix=$suffix" >&2
    else
        base_version=$version
        # Nếu không có hậu tố, thêm hậu tố -beta cho version mới
        suffix="-beta"
        echo "📌 Không có hậu tố, sẽ thêm hậu tố $suffix" >&2
    fi

    local delimiter=.
    local array=($(echo "$base_version" | tr $delimiter ' '))

    # Tăng số thứ 3 (patch version)
    array[$((${#array[@]} - 1))]=$((${array[$((${#array[@]} - 1))]} + 1))

    # Tạo version mới
    local new_version=$(local IFS=$delimiter ; echo "${array[*]}$suffix")
    echo "🔺 Version mới sau khi tăng: $new_version" >&2

    # Trả về version mới với hậu tố (nếu có)
    echo "$new_version"
}

# Hàm để lấy version hiện tại từ Docker Hub
get_latest_version() {
    # Kiểm tra xem có file .last_version không
    if [ -f ".last_version" ]; then
        local file_version=$(cat .last_version)
        echo "📄 Đọc phiên bản từ file .last_version: $file_version" >&2
    fi

    # Thử lấy tags từ Docker Hub
    echo "🔍 Đang lấy danh sách tags từ Docker Hub..." >&2
    local tags_json=$(curl -s "https://hub.docker.com/v2/repositories/$USERNAME/$APP_NAME/tags/?page_size=100")
    local tags=$(echo "$tags_json" | grep -o '"name":"[^"]*' | grep -v latest | sed 's/"name":"//g')

    if [ -z "$tags" ]; then
        echo "⚠️ Không tìm thấy tags trên Docker Hub" >&2
        # Nếu có file .last_version, sử dụng giá trị từ file
        if [ -f ".last_version" ]; then
            echo "$(cat .last_version)"
        else
            echo "1.0.1-beta"  # Version mặc định nếu không tìm thấy tags và không có file .last_version
        fi
        return
    fi

    # Hiển thị tất cả các tags để debug
    echo "📋 Tất cả các tags tìm thấy:" >&2
    echo "$tags" >&2

    # Lọc các tags là version (bao gồm cả các version có hậu tố như -beta)
    local version_tags=$(echo "$tags" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+(\-[a-zA-Z0-9]+)?$')

    if [ -z "$version_tags" ]; then
        echo "⚠️ Không tìm thấy version tags hợp lệ" >&2
        # Nếu có file .last_version, sử dụng giá trị từ file
        if [ -f ".last_version" ]; then
            echo "$(cat .last_version)"
        else
            echo "1.0.1-beta"  # Version mặc định
        fi
        return
    fi

    # Hiển thị các version tags để debug
    echo "📋 Các version tags tìm thấy:" >&2
    echo "$version_tags" >&2

    # Tách riêng các version có hậu tố beta
    local beta_versions=$(echo "$version_tags" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\-beta$')
    # Các version không có hậu tố
    local standard_versions=$(echo "$version_tags" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$')

    # Ưu tiên sử dụng version beta nếu có
    if [ -n "$beta_versions" ]; then
        # Sắp xếp các version beta và lấy version cao nhất
        local latest_beta=$(echo "$beta_versions" | sort -t. -k1,1n -k2,2n -k3,3n | tail -n1)
        echo "🔖 Phiên bản beta mới nhất: $latest_beta" >&2
        echo "$latest_beta"
    elif [ -n "$standard_versions" ]; then
        # Sắp xếp các version chuẩn và lấy version cao nhất
        local latest_standard=$(echo "$standard_versions" | sort -t. -k1,1n -k2,2n -k3,3n | tail -n1)
        echo "🔖 Phiên bản chuẩn mới nhất: $latest_standard" >&2
        echo "$latest_standard"
    else
        # Nếu không tìm thấy version phù hợp, sử dụng file .last_version hoặc giá trị mặc định
        if [ -f ".last_version" ]; then
            echo "$(cat .last_version)"
        else
            echo "1.0.1-beta"  # Version mặc định
        fi
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

# Kiểm tra xem có file .last_version không và cập nhật nếu cần
if [ -f ".last_version" ]; then
    LAST_VERSION=$(cat .last_version)
    echo "📄 Version đã lưu trong file .last_version: $LAST_VERSION"

    # So sánh với OLD_VERSION để xác định version nào mới hơn
    if [ "$LAST_VERSION" != "$OLD_VERSION" ]; then
        echo "🔄 Có sự khác biệt giữa version đã lưu ($LAST_VERSION) và version trên Docker Hub ($OLD_VERSION)"

        # So sánh version để xác định cái nào mới hơn
        LAST_BASE=${LAST_VERSION%%-*}
        OLD_BASE=${OLD_VERSION%%-*}

        # So sánh phần version cơ bản (không có hậu tố)
        if [ "$(echo "$LAST_BASE" | sed 's/\./\n/g' | wc -l)" -eq "$(echo "$OLD_BASE" | sed 's/\./\n/g' | wc -l)" ]; then
            # Nếu cùng số phần, so sánh trực tiếp
            if [ "$(echo -e "$LAST_BASE\n$OLD_BASE" | sort -t. -k1,1n -k2,2n -k3,3n | tail -n1)" = "$LAST_BASE" ]; then
                echo "🔺 Version trong file .last_version ($LAST_VERSION) mới hơn version trên Docker Hub ($OLD_VERSION)"
                OLD_VERSION=$LAST_VERSION
            else
                echo "🔺 Version trên Docker Hub ($OLD_VERSION) mới hơn version trong file .last_version ($LAST_VERSION)"
                # Cập nhật file .last_version
                echo "$OLD_VERSION" > .last_version
                echo "💾 Đã cập nhật file .last_version với version mới: $OLD_VERSION"
            fi
        fi
    fi
fi

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
docker build $BUILD_ARGS $CACHE_FROM_ARGS -t "$IMAGE_NAME:$NEW_VERSION" -f docker/Dockerfile.optimized .
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

# Hiển thị thông tin so sánh version
echo "
📈 Thông tin version:"
echo "- Version cũ (từ Docker Hub): $OLD_VERSION"
echo "- Version mới đã build: $NEW_VERSION"
echo "- Version đã lưu vào .last_version: $(cat .last_version)"

echo "
📝 Hướng dẫn sử dụng:"
echo "- Để build với version tự động tăng: ./build-and-check-optimized.sh"
echo "- Để build với version cụ thể: ./build-and-check-optimized.sh <version>"
echo "  Ví dụ: ./build-and-check-optimized.sh 2.0.5-beta"
