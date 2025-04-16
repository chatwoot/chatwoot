# Khắc phục vấn đề avatar Facebook trong Chatwoot

Tài liệu này mô tả cách khắc phục vấn đề không tải được avatar của khách hàng trên kênh Facebook trong Chatwoot.

## Vấn đề

Trong một số trường hợp, avatar của khách hàng trên kênh Facebook không được tải đúng cách, trong khi avatar trên kênh Instagram vẫn hoạt động bình thường. Điều này có thể xảy ra do nhiều nguyên nhân khác nhau, bao gồm:

1. Thay đổi trong Facebook Graph API
2. Vấn đề về quyền truy cập (Permissions)
3. Token truy cập hết hạn hoặc không hợp lệ
4. Lỗi trong quá trình tải avatar
5. Thay đổi trong cấu trúc dữ liệu webhook
6. Vấn đề với cài đặt riêng tư của người dùng

## Giải pháp

Chúng tôi đã triển khai một số cải tiến để khắc phục vấn đề này:

### 1. Sử dụng URL trực tiếp từ Graph API

Thay vì dựa vào trường `profile_pic` từ kết quả API, chúng tôi sử dụng URL trực tiếp từ Graph API để lấy avatar:

```
https://graph.facebook.com/{user-id}/picture?type=large&access_token={page-access-token}
```

### 2. Xử lý lỗi tốt hơn

Chúng tôi đã cải thiện cách xử lý lỗi khi tải avatar, bao gồm:
- Ghi log chi tiết để dễ dàng debug
- Thử lại với các tham số khác khi gặp lỗi
- Sử dụng avatar mặc định khi không thể lấy được avatar của người dùng

### 3. Tạo service riêng để lấy thông tin người dùng

Chúng tôi đã tạo một service riêng `Facebook::FetchProfileService` để lấy thông tin người dùng từ Facebook, giúp code dễ bảo trì và mở rộng hơn.

## Cách kiểm tra

Để kiểm tra xem avatar có được tải đúng cách không, bạn có thể:

1. Kiểm tra log của ứng dụng để xem có lỗi nào liên quan đến việc tải avatar không
2. Kiểm tra URL avatar trong cơ sở dữ liệu
3. Thử truy cập trực tiếp URL avatar để xem có vấn đề gì không

## Cấu hình quyền Facebook

Đảm bảo rằng ứng dụng Facebook của bạn có đủ quyền để truy cập thông tin người dùng:

1. Đăng nhập vào [Facebook Developer Dashboard](https://developers.facebook.com/)
2. Chọn ứng dụng của bạn
3. Đi đến "App Review" > "Permissions and Features"
4. Đảm bảo rằng ứng dụng của bạn có quyền `public_profile`

## Cập nhật token truy cập

Nếu token truy cập hết hạn hoặc không hợp lệ, bạn cần cập nhật token:

1. Đăng nhập vào [Facebook Developer Dashboard](https://developers.facebook.com/)
2. Chọn ứng dụng của bạn
3. Đi đến "Tools" > "Graph API Explorer"
4. Tạo một token mới và cập nhật trong Chatwoot

## Vấn đề đã biết

1. **Cài đặt riêng tư của người dùng**: Nếu người dùng đã hạn chế quyền truy cập vào thông tin cá nhân, bạn có thể không lấy được avatar của họ.
2. **Thay đổi trong Facebook API**: Facebook thường xuyên cập nhật API của họ, có thể dẫn đến vấn đề với avatar.

## Liên hệ hỗ trợ

Nếu bạn vẫn gặp vấn đề với avatar Facebook sau khi thực hiện các bước trên, vui lòng liên hệ với chúng tôi để được hỗ trợ thêm.
