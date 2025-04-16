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

# Scratchpad

## Tối ưu hiệu năng gửi hình ảnh lên Facebook

[X] Tìm hiểu logic hiện tại về xử lý hình ảnh khi gửi lên Facebook
  [X] Kiểm tra service xử lý gửi tin nhắn Facebook
  [X] Kiểm tra cách xử lý hình ảnh trong tin nhắn
  [X] Xác định điểm nghẽn hiệu năng
[X] Tìm hiểu API Facebook về việc gửi hình ảnh
  [X] Kiểm tra xem Facebook có hỗ trợ gửi URL hình ảnh trực tiếp không
  [X] Tìm tài liệu API về việc gửi hình ảnh qua URL
[X] Đề xuất giải pháp tối ưu
  [X] So sánh phương pháp hiện tại với phương pháp gửi URL
  [X] Đánh giá ưu nhược điểm
[X] Thực hiện các thay đổi cần thiết
  [X] Cập nhật Facebook::SendOnFacebookService để gửi URL hình ảnh trực tiếp
  [X] Tạo phương thức mới để xử lý gửi hình ảnh tối ưu
  [ ] Tạo background job để xử lý việc gửi hình ảnh bất đồng bộ (phần mở rộng)
  [ ] Cập nhật logic xử lý hình ảnh từ front-end (phần mở rộng)
  [ ] Kiểm tra hiệu năng sau khi thay đổi

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
