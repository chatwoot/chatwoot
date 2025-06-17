# Mooly.vn Widget Optimization

## Tổng quan
Đã tối ưu widget Chatwoot/Mooly với các tính năng animation thu hút người dùng và loại bỏ branding không cần thiết.

## Các tính năng đã thêm

### 1. Animation Thu Hút
- **Pulse Effect**: Widget bubble có hiệu ứng nhấp nháy nhẹ nhàng
- **Glow Effect**: Ánh sáng xung quanh bubble tạo sự chú ý
- **Hover Animation**: Phóng to và bounce khi hover
- **Shake Effect**: Rung nhẹ khi có tin nhắn mới

### 2. Text Typing Animation
- **Continuous Typing**: Text hiển thị liên tục với hiệu ứng typing
- **Multiple Messages**: Xoay vòng 8 tin nhắn khác nhau
- **Cursor Blink**: Con trỏ nhấp nháy như đang gõ
- **Auto Start/Stop**: Tự động dừng khi mở chat, khởi động lại khi đóng

### 3. Danh sách Text Typing
```javascript
const MOOLY_TYPING_TEXTS = [
  'Xin chào! Tôi có thể giúp gì cho bạn?',
  'Hỗ trợ 24/7 - Luôn sẵn sàng!',
  'Chat ngay để được tư vấn miễn phí',
  'Mooly.vn - Giải pháp AI thông minh',
  'Bạn cần hỗ trợ gì không?',
  'Nhấn để bắt đầu trò chuyện',
  'AI Assistant đang chờ bạn...',
  'Tư vấn nhanh - Phản hồi tức thì'
];
```

### 4. Loại bỏ Branding
- Đã xóa dòng "CC bởi Chatwoot" khỏi footer widget
- Widget hiện tại hoàn toàn clean không có link về Chatwoot

### 5. Responsive Design
- Tối ưu cho mobile với font size và width phù hợp
- Animation mượt mà trên mọi thiết bị

## Files đã chỉnh sửa

### 1. `app/javascript/widget/components/layouts/ViewWithHeader.vue`
- Loại bỏ component Branding

### 2. `app/javascript/sdk/sdk.js`
- Thêm CSS animations: pulse, glow, bounce, shake, typing
- Cải thiện hover effects
- Responsive design cho mobile

### 3. `app/javascript/sdk/bubbleHelpers.js`
- Thêm function `startMoolyTypingAnimation()`
- Thêm function `stopMoolyTypingAnimation()`
- Tích hợp typing animation vào bubble lifecycle

## Cách sử dụng

### Cấu hình Widget Type
Để sử dụng typing animation, cần set widget type là 'expanded_bubble':

```javascript
window.chatwootSettings = {
  type: 'expanded_bubble',
  position: 'right',
  // ... other settings
};
```

### Tùy chỉnh Text Messages
Có thể chỉnh sửa danh sách text trong file `bubbleHelpers.js`:

```javascript
const MOOLY_TYPING_TEXTS = [
  'Tin nhắn tùy chỉnh 1',
  'Tin nhắn tùy chỉnh 2',
  // ... thêm tin nhắn
];
```

### Tùy chỉnh Animation Speed
Có thể điều chỉnh tốc độ typing trong function `typeText()`:

```javascript
// Tốc độ gõ (ms per character)
typingInterval = setInterval(typeText, isTypingForward ? 100 : 50);

// Thời gian pause giữa các tin nhắn
setTimeout(() => {
  isTypingForward = false;
}, 2000); // 2 giây
```

## Animation CSS Classes

### Keyframes đã thêm:
- `mooly-pulse`: Hiệu ứng nhấp nháy
- `mooly-glow`: Hiệu ứng ánh sáng
- `mooly-bounce`: Hiệu ứng nảy
- `mooly-shake`: Hiệu ứng rung
- `mooly-typing`: Hiệu ứng typing
- `mooly-cursor-blink`: Con trỏ nhấp nháy

### CSS Classes áp dụng:
- `.woot-widget-bubble`: Animation cơ bản
- `.woot-widget-bubble:hover`: Hiệu ứng hover
- `.woot-widget-bubble.unread-notification`: Animation khi có tin nhắn mới
- `.woot-widget-bubble.woot-widget--expanded`: Expanded bubble với typing

## Performance
- Tất cả animation sử dụng CSS transforms và opacity để tối ưu performance
- Typing animation tự động dừng khi không cần thiết
- Responsive và mượt mà trên mobile

## Browser Support
- Chrome/Edge: Full support
- Firefox: Full support  
- Safari: Full support
- Mobile browsers: Optimized

## API Functions

### Global MoolyWidget Object
Sau khi widget load, có thể sử dụng các function sau:

```javascript
// Thay đổi danh sách text typing
window.MoolyWidget.setTypingTexts([
  'Text mới 1',
  'Text mới 2',
  'Text mới 3'
]);

// Bật/tắt typing animation
window.MoolyWidget.startTyping();
window.MoolyWidget.stopTyping();

// Bật/tắt tất cả animation
window.MoolyWidget.toggleAnimation(true); // bật
window.MoolyWidget.toggleAnimation(false); // tắt

// Thay đổi màu bubble
window.MoolyWidget.setBubbleColor('#ff6b6b');

// Bật/tắt rainbow animation
window.MoolyWidget.enableRainbow(true); // bật
window.MoolyWidget.enableRainbow(false); // tắt
```

### Sử dụng trong website
```html
<script>
window.addEventListener('chatwoot:ready', function() {
  // Tùy chỉnh text cho website cụ thể
  window.MoolyWidget.setTypingTexts([
    'Chào mừng đến với website ABC',
    'Cần hỗ trợ mua hàng?',
    'Tư vấn miễn phí 24/7'
  ]);

  // Thay đổi màu theo brand
  window.MoolyWidget.setBubbleColor('#your-brand-color');
});
</script>
```

## Troubleshooting

### Animation không hoạt động
1. Kiểm tra widget type phải là 'expanded_bubble'
2. Đảm bảo JavaScript không bị lỗi
3. Kiểm tra CSS đã load đúng

### Text không hiển thị
1. Kiểm tra element `#woot-widget--expanded__text` có tồn tại
2. Đảm bảo function `startMoolyTypingAnimation()` được gọi
3. Kiểm tra console log để debug

### Mobile không responsive
1. Kiểm tra viewport meta tag
2. Đảm bảo CSS media queries hoạt động
3. Test trên thiết bị thật

### API functions không hoạt động
1. Đảm bảo widget đã load hoàn toàn
2. Sử dụng trong event 'chatwoot:ready'
3. Kiểm tra `window.MoolyWidget` có tồn tại

## Advanced Features

### Rainbow Animation
Hiệu ứng đổi màu cầu vồng cho bubble:
```javascript
window.MoolyWidget.enableRainbow(true);
```

### Custom Animation Control
Có thể tùy chỉnh hoàn toàn animation theo nhu cầu:
```javascript
// Tắt tất cả animation mặc định
window.MoolyWidget.toggleAnimation(false);

// Tự tạo animation riêng
const bubble = document.querySelector('.woot-widget-bubble');
bubble.style.animation = 'your-custom-animation 2s infinite';
```

## Kết luận
Widget Mooly.vn hiện tại đã được tối ưu hoàn toàn với:
- ✅ Animation thu hút người dùng (pulse, glow, bounce, shake)
- ✅ Text typing liên tục với 8 tin nhắn mặc định
- ✅ Loại bỏ branding Chatwoot hoàn toàn
- ✅ Responsive design cho mọi thiết bị
- ✅ Performance tối ưu với CSS transforms
- ✅ Browser compatibility đầy đủ
- ✅ API functions để tùy chỉnh từ bên ngoài
- ✅ Rainbow animation và custom color
- ✅ Global MoolyWidget object để control

### Tính năng nổi bật:
1. **Smart Typing**: Tự động dừng khi mở chat, khởi động lại khi đóng
2. **Customizable**: Có thể thay đổi text, màu sắc, animation từ JavaScript
3. **Mobile Optimized**: Hoạt động mượt mà trên mobile
4. **Zero Branding**: Không còn dấu vết Chatwoot
5. **Production Ready**: Đã test và tối ưu cho production

Widget sẵn sàng để deploy và sử dụng trong production environment!

---

## 🆕 UPDATE: Typing Texts Configuration UI

### Tính năng mới đã thêm:

#### 1. **Database Schema Update**
- Thêm column `typing_texts` (jsonb) vào table `channel_web_widgets`
- Index GIN cho performance tối ưu
- Migration tự động set default texts cho existing records

#### 2. **Admin UI Configuration**
- Component `TypingTextsManager.vue` trong Widget Builder
- Drag & drop để sắp xếp thứ tự
- Real-time editing với character count
- Validation: max 20 texts, max 100 chars each
- Reset to default button

#### 3. **API Integration**
- Typing texts được lưu trong database
- Tự động sync với widget config
- Validation server-side

#### 4. **Widget SDK Integration**
- Tự động load typing texts từ config
- Fallback to default nếu không có config
- API để update texts runtime

### Cách sử dụng UI Configuration:

#### 1. **Truy cập Widget Builder**
```
Dashboard → Settings → Inboxes → [Select Web Widget] → Widget Builder
```

#### 2. **Cấu hình Typing Texts**
- Scroll xuống section "Typing Animation Texts"
- Add/Edit/Remove texts
- Drag để sắp xếp thứ tự
- Click "Update Widget Settings" để lưu

#### 3. **Tính năng UI**
- ✅ Add new text với validation
- ✅ Edit inline với character counter
- ✅ Drag & drop reorder
- ✅ Remove individual texts
- ✅ Reset to default
- ✅ Real-time preview

#### 4. **Validation Rules**
- Maximum 20 texts per inbox
- Maximum 100 characters per text
- No empty texts allowed
- No duplicate texts

### Files đã thêm/chỉnh sửa:

#### Database:
- `db/migrate/20241216000001_add_typing_texts_to_channel_web_widgets.rb`

#### Backend:
- `app/models/channel/web_widget.rb` - Added typing_texts to EDITABLE_ATTRS + validation
- `app/views/api/v1/models/_inbox.json.jbuilder` - Include typing_texts in API
- `app/views/api/v1/widget/configs/create.json.jbuilder` - Include in widget config

#### Frontend:
- `app/javascript/dashboard/components/widgets/TypingTextsManager.vue` - New component
- `app/javascript/dashboard/routes/dashboard/settings/inbox/WidgetBuilder.vue` - Integration
- `app/javascript/dashboard/i18n/locale/en/inboxMgmt.json` - i18n keys

#### Widget SDK:
- `app/javascript/sdk/bubbleHelpers.js` - Load texts from config

### Migration Command:
```bash
bundle exec rails db:migrate
```

### Kết quả:
- ✅ Admin có thể tùy chỉnh typing texts qua UI
- ✅ Mỗi inbox có thể có texts riêng
- ✅ Tự động sync với widget
- ✅ Validation đầy đủ
- ✅ User-friendly interface
- ✅ Backward compatibility

### Demo Usage:
1. Tạo inbox web widget mới
2. Vào Widget Builder
3. Cấu hình typing texts theo nhu cầu
4. Set widget type = "expanded_bubble"
5. Copy script và embed vào website
6. Typing texts sẽ hiển thị theo cấu hình!

**Perfect solution for customizable typing animations! 🎉**
