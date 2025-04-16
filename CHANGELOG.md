# Changelog

## [Unreleased]

### Added
- External URL Attachments cho Instagram: Hỗ trợ gửi tin nhắn với tệp đính kèm sử dụng external_url cho kênh Instagram, giúp tối ưu hiệu năng khi gửi tin nhắn có hình ảnh.
- Cập nhật tài liệu API để mô tả cách sử dụng external_url trong Chatwoot.
- Thêm service Facebook::FetchProfileService để xử lý việc lấy thông tin người dùng Facebook một cách đáng tin cậy hơn.
- Thêm tài liệu hướng dẫn khắc phục vấn đề avatar Facebook.

### Changed
- Cải thiện hiệu năng gửi tin nhắn có hình ảnh đến Instagram bằng cách sử dụng external_url thay vì tải hình ảnh về Chatwoot trước.

### Fixed
- Sửa lỗi khi gửi tin nhắn có hình ảnh đến Instagram.
- Sửa lỗi không tải được avatar của khách hàng trên kênh Facebook bằng cách sử dụng URL trực tiếp từ Graph API.
- Cải thiện cách xử lý lỗi khi tải avatar, bao gồm việc thử lại với các tham số khác khi gặp lỗi.

## [1.0.0] - 2023-01-01

### Added
- Tính năng ban đầu của Chatwoot.
