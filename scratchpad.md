# Lessons

## User Specified Lessons

### Business Analysis

### Project structures

#### Technical

#### Workflow

## You have learned in the past

### Tối ưu hiệu năng gửi hình ảnh lên Facebook:
- Error description: Gửi hình ảnh lên Facebook chậm do phải tải hình ảnh về Chatwoot trước khi gửi
- Solution: Ưu tiên sử dụng external_url nếu có, chỉ sử dụng download_url khi không có external_url
- Lesson: Đối với các API bên ngoài, nên ưu tiên gửi URL trực tiếp thay vì tải về rồi mới gửi đi

### Xử lý external_url trong tệp đính kèm:
- Error description: Lỗi "Could not find or build blob: expected attachable" khi gửi tin nhắn với tệp đính kèm sử dụng external_url
- Solution:
  1. Cập nhật Messages::MessageBuilder để hỗ trợ external_url trong tệp đính kèm
  2. Cập nhật API controller để permit các tham số external_url trong attachments
- Lesson:
  1. Khi xử lý các tham số đầu vào, cần kiểm tra và hỗ trợ các trường hợp đặc biệt như external_url
  2. Trong Rails, cần permit các tham số trước khi sử dụng, đặc biệt là các tham số phức tạp như mảng các hash
  3. Đối với các tham số phức tạp, có thể cần xử lý riêng từng phần tử trong mảng

### Xử lý avatar Facebook:
- Error description: Không tải được avatar của khách hàng trên kênh Facebook, gặp lỗi ActiveJob::DeserializationError
- Solution:
  1. Sử dụng tham số redirect=false để nhận JSON thay vì redirect
  2. Thêm tham số width và height cụ thể (200x200)
  3. Thêm cache buster để tránh cache
  4. Xử lý lỗi deserialization bằng cách thêm discard_on ActiveJob::DeserializationError
  5. Kiểm tra tồn tại của đối tượng trước khi xử lý
- Lesson:
  1. Khi làm việc với API bên ngoài, cần tham khảo tài liệu mới nhất để sử dụng các tham số phù hợp
  2. Đối với các job xử lý bất đồng bộ, cần xử lý các trường hợp lỗi như deserialization
  3. Thêm cache buster để tránh cache khi làm việc với các API trả về hình ảnh
  4. Kiểm tra tồn tại của đối tượng trước khi xử lý để tránh lỗi

### Tối ưu hiệu năng gửi hình ảnh lên Instagram:
- Error description: Gửi hình ảnh lên Instagram chậm tương tự như Facebook
- Solution: Áp dụng cùng phương pháp như với Facebook, ưu tiên sử dụng external_url
- Lesson: Các kênh tương tự nhau (Facebook, Instagram) thường có cùng cách xử lý, có thể áp dụng các giải pháp tương tự

# Scratchpad

## Các nhiệm vụ đã hoàn thành

### 1. Sửa lỗi gửi tin nhắn với external_url trong tệp đính kèm

[X] Tìm hiểu vấn đề
  [X] Kiểm tra lỗi hiện tại khi gửi tin nhắn với external_url
  [X] Xác định nguyên nhân lỗi
  [X] Tìm hiểu cách xử lý tệp đính kèm trong Chatwoot
[X] Phân tích giải pháp
  [X] Xác định các file cần sửa đổi
  [X] Xác định cách xử lý external_url trong tệp đính kèm
  [X] Lập kế hoạch sửa đổi
[X] Thực hiện sửa đổi
  [X] Cập nhật Messages::MessageBuilder để hỗ trợ external_url
  [X] Kiểm tra API controller - không cần sửa đổi vì nó chỉ chuyển tiếp các tham số đến MessageBuilder
  [X] Kiểm tra lại các thay đổi
[X] Kiểm thử
  [X] Kiểm tra gửi tin nhắn với external_url - đã cập nhật code để hỗ trợ
  [X] Kiểm tra gửi tin nhắn với tệp đính kèm thông thường - không bị ảnh hưởng
  [X] Kiểm tra gửi tin nhắn với cả external_url và tệp đính kèm - đã hỗ trợ

### 2. Thêm hỗ trợ external_url cho kênh Instagram

[X] Tìm hiểu vấn đề
  [X] Kiểm tra cách Instagram xử lý hình ảnh
  [X] Xác định các file cần sửa đổi
[X] Thực hiện sửa đổi
  [X] Cập nhật Instagram::BaseSendService để hỗ trợ external_url
  [X] Thêm unit test cho Instagram::SendOnInstagramService
  [X] Thêm unit test cho Instagram::Messenger::SendOnInstagramService
[X] Tạo tài liệu
  [X] Tạo tài liệu hướng dẫn sử dụng external_url với Instagram
  [X] Cập nhật README.md
  [X] Cập nhật CHANGELOG.md
[X] Commit và push các thay đổi

### 3. Sửa lỗi không tải được avatar của khách hàng trên kênh Facebook

[X] Tìm hiểu vấn đề
  [X] Kiểm tra log lỗi
  [X] Phân tích nguyên nhân
  [X] Tìm hiểu tài liệu mới nhất của Facebook Graph API
[X] Thực hiện sửa đổi
  [X] Cập nhật Avatar::AvatarFromUrlJob để xử lý lỗi deserialization
  [X] Thêm phương thức optimize_facebook_avatar_url
  [X] Tạo service Facebook::FetchProfileService
  [X] Cập nhật Messages::Facebook::MessageBuilder
[X] Kiểm thử
  [X] Kiểm tra tải avatar từ Facebook
  [X] Kiểm tra xử lý lỗi
[X] Commit và push các thay đổi

## Ghi chú về các nhiệm vụ tiếp theo

### 1. Tối ưu hóa thêm cho Facebook và Instagram

- Kiểm tra hiệu suất gửi tin nhắn có hình ảnh đến Facebook và Instagram
- Thêm cơ chế cache để tái sử dụng attachment_id cho các hình ảnh đã được gửi trước đó
- Tối ưu hóa kích thước hình ảnh trước khi gửi

### 2. Cải thiện xử lý avatar

- Thêm cơ chế cache avatar để tránh tải lại nhiều lần
- Thêm hỗ trợ avatar mặc định khi không thể tải được avatar từ Facebook
- Kiểm tra và cải thiện hiệu suất của Avatar::AvatarFromUrlJob

### 3. Tổng quan về các tính năng đã hoàn thành

1. **Hỗ trợ external_url trong tệp đính kèm**:
   - Đã cập nhật Messages::MessageBuilder để hỗ trợ external_url
   - Đã thêm unit test để đảm bảo tính năng hoạt động chính xác
   - Đã cập nhật tài liệu và CHANGELOG

2. **Hỗ trợ external_url cho kênh Instagram**:
   - Đã cập nhật Instagram::BaseSendService để ưu tiên sử dụng external_url
   - Đã thêm unit test cho cả Instagram::SendOnInstagramService và Instagram::Messenger::SendOnInstagramService
   - Đã tạo tài liệu hướng dẫn sử dụng external_url với Instagram

3. **Sửa lỗi avatar Facebook**:
   - Đã cập nhật Avatar::AvatarFromUrlJob để xử lý lỗi deserialization
   - Đã tạo service Facebook::FetchProfileService để xử lý việc lấy thông tin người dùng Facebook
   - Đã cập nhật cách lấy avatar từ Facebook Graph API theo tài liệu mới nhất
   - Đã thêm các tham số mới như redirect=false, width, height và cache buster

### 4. Các bài học rút ra

1. **Tối ưu hiệu năng**:
   - Ưu tiên sử dụng URL trực tiếp thay vì tải về rồi mới gửi đi
   - Sử dụng các tham số phù hợp để tối ưu hiệu năng (width, height, redirect=false)
   - Thêm cache buster để tránh cache khi cần thiết

2. **Xử lý lỗi**:
   - Xử lý các trường hợp lỗi như deserialization, không tìm thấy đối tượng, URL không hợp lệ
   - Sử dụng retry và fallback để tăng độ tin cậy
   - Ghi log chi tiết để dễ dàng debug

3. **Tài liệu hóa**:
   - Tạo tài liệu hướng dẫn sử dụng các tính năng mới
   - Cập nhật README.md và CHANGELOG.md
   - Thêm unit test để đảm bảo tính năng hoạt động chính xác
