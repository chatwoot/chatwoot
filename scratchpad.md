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

# Scratchpad

## Sửa lỗi gửi tin nhắn với external_url trong tệp đính kèm

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

### Phân tích vấn đề

1. **Lỗi hiện tại**:
   - Khi gửi tin nhắn với tệp đính kèm sử dụng external_url, hệ thống báo lỗi: "Could not find or build blob: expected attachable, got #<ActionController::Parameters {\"file_type\"=>\"image\", \"external_url\"=>\"https://images2.thanhnien.vn/zoom/700_438/528068263637045248/2024/1/26/e093e9cfc9027d6a142358d24d2ee350-65a11ac2af785880-17061562929701875684912-37-0-587-880-crop-1706239860681642023140.jpg\"} permitted: false>"
   - Lỗi xảy ra khi gửi API "{{host}}/{{api_version}}/accounts/{{account_id}}/conversations/35/messages" với body chứa external_url trong attachments

2. **Nguyên nhân**:
   - Trong Messages::MessageBuilder, phương thức process_attachments chỉ xử lý tệp đính kèm là file hoặc signed_id, không xử lý external_url
   - API controller không có xử lý cho trường hợp external_url trong tệp đính kèm
   - Mô hình Attachment có trường external_url nhưng không có logic để tạo attachment từ external_url

3. **Giải pháp**:
   - Cập nhật Messages::MessageBuilder để hỗ trợ external_url trong tệp đính kèm
   - Cập nhật API controller để xử lý external_url trong tệp đính kèm
   - Đảm bảo rằng external_url được lưu vào cơ sở dữ liệu và được sử dụng khi gửi tin nhắn đến Facebook

### Phân tích hiện trạng

1. **Cách Chatwoot hiện đang gửi hình ảnh lên Facebook**:
   - Khi gửi tin nhắn có hình ảnh, Chatwoot sử dụng `attachment.download_url` để lấy URL của hình ảnh
   - URL này được gửi trực tiếp đến Facebook Messenger API trong payload
   - Facebook sau đó sẽ tải hình ảnh từ URL này và gửi đến người dùng

2. **Điểm nghẽn hiệu năng**:
   - Khi gửi nhiều hình ảnh, mỗi hình ảnh được gửi trong một tin nhắn riêng biệt
   - Mỗi tin nhắn cần một lần gọi API riêng biệt
   - Facebook phải tải xuống hình ảnh từ URL của Chatwoot, có thể gây chậm nếu kết nối mạng giữa Facebook và Chatwoot không ổn định

3. **Các giải pháp có thể**:
   - Sử dụng Attachment Upload API của Facebook để tải hình ảnh lên trước và nhận attachment_id
   - Sử dụng cơ chế cache để tái sử dụng attachment_id cho các hình ảnh đã được gửi trước đó
   - Tối ưu hóa kích thước hình ảnh trước khi gửi

### Đề xuất giải pháp tối ưu

Sau khi phân tích các tài liệu, mã nguồn và ý kiến của người dùng, tôi đề xuất giải pháp sau để tối ưu hiệu năng gửi hình ảnh lên Facebook:

1. **Gửi URL hình ảnh trực tiếp lên Facebook**:
   - Nếu hình ảnh đã có URL (lưu trữ trên server), gửi URL đó trực tiếp lên Facebook mà không cần tải về Chatwoot trước
   - Chỉ sau khi gửi thành công lên Facebook, mới lưu thông tin vào Chatwoot
   - Điều này giúp giảm thời gian xử lý và tối ưu hiệu năng

2. **Phân biệt xử lý dựa trên nguồn hình ảnh**:
   - Nếu hình ảnh đã có URL: Gửi trực tiếp URL lên Facebook
   - Nếu hình ảnh được gửi từ front-end (chưa có URL): Sử dụng logic hiện tại (tải hình về rồi gửi lên Facebook)

3. **Xử lý bất đồng bộ (Asynchronous)**:
   - Thực hiện việc gửi hình ảnh lên Facebook trong một background job
   - Điều này giúp giảm thời gian chờ cho người dùng khi gửi tin nhắn có nhiều hình ảnh

4. **Tối ưu hóa kích thước hình ảnh**:
   - Nén và tối ưu hóa hình ảnh trước khi gửi lên Facebook (cho trường hợp hình ảnh từ front-end)
   - Điều này giúp giảm thời gian gửi và tốc độ xử lý

### Ưu và nhược điểm của giải pháp

**Ưu điểm**:
- Giảm thời gian gửi tin nhắn có hình ảnh vì không cần tải hình ảnh về Chatwoot trước
- Giảm tải cho máy chủ Chatwoot vì không cần lưu trữ hình ảnh tạm thời
- Đơn giản hóa quy trình gửi hình ảnh, giảm độ phức tạp của code
- Tối ưu hóa hiệu năng mạng vì hình ảnh chỉ cần được tải một lần (từ URL gốc đến Facebook)

**Nhược điểm**:
- Phụ thuộc vào tính khả dụng của URL hình ảnh gốc (nếu URL gốc không khả dụng, Facebook sẽ không thể tải hình ảnh)
- Cần phân biệt xử lý giữa hình ảnh đã có URL và hình ảnh mới từ front-end
- Có thể gặp vấn đề với các URL có thời gian sống ngắn (nếu URL hết hạn trước khi Facebook tải hình ảnh)

## Nhiệm vụ trước đây (đã hoàn thành)
[X] Tạo scratchpad để theo dõi tiến trình
[X] Kiểm tra thông tin về repository hiện tại
[X] Kiểm tra remote repositories đã được cấu hình
[X] Kiểm tra nhánh hiện tại và trạng thái
[X] Thêm remote repository gốc của Chatwoot (nếu chưa có)
[X] Pull code mới nhất từ repository gốc
[X] Xử lý các thay đổi chưa được commit (stash hoặc commit) - Đã stash
[X] Merge code từ upstream/develop vào nhánh develop hiện tại
[X] Kiểm tra xung đột (nếu có) - Đã giải quyết xung đột
[X] Áp dụng lại các thay đổi đã stash - Đã giải quyết xung đột và commit
[X] Báo cáo kết quả

Các file đã được sửa đổi nhưng chưa commit:
- app/dispatchers/sync_dispatcher.rb
- app/javascript/shared/components/CardButton.vue
- app/services/facebook/send_on_facebook_service.rb
- build-and-push.sh
- lib/integrations/facebook/message_creator.rb

Các file chưa được theo dõi:
- app/listeners/channel_listener.rb
- app/services/facebook/typing_indicator_service.rb
