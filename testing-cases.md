# WhatsApp Template Testing Cases

This document contains test cases for WhatsApp template functionality in Chatwoot, with screenshots showing expected behavior in both Chatwoot UI and WhatsApp delivery.

### hello_world

**Template Details:**
- **Name**: `hello_world`
- **Category**: UTILITY
- **Type**: Text Header + Body + Footer
- **Components**:
  - Header: "Hello World" (TEXT)
  - Body: "Welcome and congratulations!! This message demonstrates your ability to send a WhatsApp message notification from the Cloud API, hosted by Meta. Thank you for taking the time to test with us."
  - Footer: "WhatsApp Business Platform sample message"


**Chatwoot UI**

![Chatwoot Template Configuration](templates/hello_world_chatwoot.png)

**WhatsApp Delivery**


![WhatsApp Delivered Message](templates/hello_world_whatsapp.png)

### greet

**Template Details:**
- **Name**: `greet`
- **Category**: MARKETING
- **Type**: Text Only (Body with Named Parameter)
- **Components**:
  - Body: "Hey {{customer_name}} how may I help you?"
- **Parameters**: 
  - `customer_name` (NAMED parameter format)

**Chatwoot UI**

![Chatwoot Template Configuration](templates/greet_chatwoot.png)

**WhatsApp Delivery**

![WhatsApp Delivered Message](templates/greet_whatsapp.png)

### delivery_confirmation

**Template Details:**
- **Name**: `delivery_confirmation`
- **Category**: UTILITY
- **Type**: Text Only (Body with Positional Parameters)
- **Components**:
  - Body: "{{1}}, your order was successfully delivered on {{2}}.\n\nThank you for your purchase.\n"
- **Parameters**: 
  - `{{1}}` - Customer name (POSITIONAL)
  - `{{2}}` - Delivery date (POSITIONAL)

**Chatwoot UI**

![Chatwoot Template Configuration](templates/delivery_confirmation_chatwoot.png)

**WhatsApp Delivery**

![WhatsApp Delivered Message](templates/delivery_confirmation_whatsapp.png)

### address_update

**Template Details:**
- **Name**: `address_update`
- **Category**: UTILITY
- **Type**: Text Header + Body (Positional Parameters)
- **Components**:
  - Header: "Address update" (TEXT)
  - Body: "Hi {{1}}, your delivery address has been successfully updated to {{2}}. Contact {{3}} for any inquiries."
- **Parameters**: 
  - `{{1}}` - Customer name (POSITIONAL)
  - `{{2}}` - New address (POSITIONAL)
  - `{{3}}` - Contact info (POSITIONAL)

#### Chatwoot UI

![Chatwoot Template Configuration](templates/address_update_chatwoot.png)

#### WhatsApp Delivery

![WhatsApp Delivered Message](templates/address_update_whatsapp.png)

### order_confirmation

**Template Details:**
- **Name**: `order_confirmation`
- **Category**: MARKETING
- **Type**: Image Header + Body (Positional Parameters)
- **Components**:
  - Header: IMAGE format
  - Body: "Hi your order {{1}} is confirmed. Please wait for further updates"
- **Parameters**: 
  - Media URL for image header
  - `{{1}}` - Order details (POSITIONAL)

**Chatwoot UI**

![Chatwoot Template Configuration](templates/order_confirmation_chatwoot.png)

**WhatsApp Delivery**

![WhatsApp Delivered Message](templates/order_confirmation_whatsapp.png)

### product_launch

**Template Details:**
- **Name**: `product_launch`
- **Category**: MARKETING
- **Type**: Image Header + Body + Footer (Named Parameters)
- **Components**:
  - Header: IMAGE format
  - Body: "New arrival! Our stunning coat now available in {{color}} color."
  - Footer: "Free shipping on orders over $100. Limited time offer."
- **Parameters**: 
  - Media URL for image header
  - `color` - Product color (NAMED)

**Chatwoot UI**

![Chatwoot Template Configuration](templates/product_launch_chatwoot.png)

**WhatsApp Delivery**

![WhatsApp Delivered Message](templates/product_launch_whatsapp.png)

### training_video

**Template Details:**
- **Name**: `training_video`
- **Category**: MARKETING
- **Type**: Video Header + Body (Named Parameters)
- **Components**:
  - Header: VIDEO format
  - Body: "Hi {{name}}, here's your training video. Please watch by{{date}}."
- **Parameters**: 
  - Media URL for video header
  - `name` - Employee name (NAMED)
  - `date` - Due date (NAMED)

**Chatwoot UI**

![Chatwoot Template Configuration](templates/training_video_chatwoot.png)

**WhatsApp Delivery**

![WhatsApp Delivered Message](templates/training_video_whatsapp.png)

### purchase_receipt

**Template Details:**
- **Name**: `purchase_receipt`
- **Category**: UTILITY
- **Type**: Document Header + Body (Positional Parameters)
- **Components**:
  - Header: DOCUMENT format
  - Body: "Thank you for using your {{1}} card at {{2}}. Your {{3}} is attached as a PDF."
- **Parameters**: 
  - Media URL for document header
  - `{{1}}` - Card type (POSITIONAL)
  - `{{2}}` - Merchant name (POSITIONAL)
  - `{{3}}` - Document type (POSITIONAL)

    **Chatwoot UI**

![Chatwoot Template Configuration](templates/purchase_receipt_chatwoot.png)

**WhatsApp Delivery**

![WhatsApp Delivered Message](templates/purchase_receipt_whatsapp.png)

### event_invitation_static

**Template Details:**
- **Name**: `event_invitation_static`
- **Category**: MARKETING
- **Type**: Body + Static URL Buttons (Named Parameters)
- **Components**:
  - Body: "You're invited to {{event_name}} at {{location}}, Join us for an amazing experience!"
  - Buttons: 2 URL buttons ("Visit website", "Get Directions") with static URLs
- **Parameters**: 
  - `event_name` - Event name (NAMED)
  - `location` - Event location (NAMED)
- **Button URLs**:
  - Visit website: `https://events.example.com/register` (static)
  - Get Directions: `https://maps.app.goo.gl/YoWAzRj1GDuxs6qz8` (static)

**Chatwoot UI**

![Chatwoot Template Configuration](templates/event_invitation_static_chatwoot.png)

**WhatsApp Delivery**

![WhatsApp Delivered Message](templates/event_invitation_static_whatsapp.png)

### feedback_request

**Template Details:**
- **Name**: `feedback_request`
- **Category**: MARKETING
- **Type**: Body + URL Button (Named Parameters)
- **Components**:
  - Body: "Hey {{name}}, how was your experience with Puma? We'd love your feedback!"
  - Buttons: 1 URL button ("Leave Feedback") with static URL
- **Parameters**: 
  - `name` - Customer name (NAMED)
- **Button URL**:
  - Leave Feedback: `https://feedback.example.com/survey` (static)

**Chatwoot UI**

![Chatwoot Template Configuration](templates/feedback_request_chatwoot.png)

**WhatsApp Delivery**

![WhatsApp Delivered Message](templates/feedback_request_whatsapp.png)

### support_callback

**Template Details:**
- **Name**: `support_callback`
- **Category**: UTILITY
- **Type**: Body + Phone Button (Named Parameters)
- **Components**:
  - Body: "Hello {{name}}, our support team will call you regarding ticket # {{ticket_id}}."
  - Buttons: 1 PHONE_NUMBER button ("Call Support")
- **Parameters**: 
  - `name` - Customer name (NAMED)
  - `ticket_id` - Support ticket ID (NAMED)

**Chatwoot UI**

![Chatwoot Template Configuration](templates/support_callback_chatwoot.png)

**WhatsApp Delivery**

![WhatsApp Delivered Message](templates/support_callback_whatsapp.png)

### discount_coupon

**Template Details:**
- **Name**: `discount_coupon`
- **Category**: MARKETING
- **Type**: Body + Copy Code Button (Named Parameters)
- **Components**:
  - Body: "🎉 Special offer for you! Get {{discount_percentage}}% off your next purchase. Use the code below at checkout"
  - Buttons: 1 COPY_CODE button ("Copy offer code")
- **Parameters**: 
  - `discount_percentage` - Discount amount (NAMED)
  - Coupon code for button

**Chatwoot UI**

![Chatwoot Template Configuration](templates/discount_coupon_chatwoot.png)

**WhatsApp Delivery**

![WhatsApp Delivered Message](templates/discount_coupon_whatsapp.png)

### technician_visit

**Template Details:**
- **Name**: `technician_visit`
- **Category**: UTILITY
- **Type**: Text Header + Body + Quick Reply Buttons (Positional Parameters)
- **Components**:
  - Header: "Technician visit" (TEXT)
  - Body: "Hi {{1}}, we're scheduling a technician visit to {{2}} on {{3}} between {{4}} and {{5}}. Please confirm if this time slot works for you."
  - Buttons: 2 QUICK_REPLY buttons ("Confirm", "Reschedule")
- **Parameters**: 
  - `{{1}}` - Customer name (POSITIONAL)
  - `{{2}}` - Address (POSITIONAL)
  - `{{3}}` - Date (POSITIONAL)
  - `{{4}}` - Start time (POSITIONAL)
  - `{{5}}` - End time (POSITIONAL)

**Chatwoot UI**

![Chatwoot Template Configuration](templates/technician_visit_chatwoot.png)

**WhatsApp Delivery**

![WhatsApp Delivered Message](templates/technician_visit_whatsapp.png)

### basic_otp

**Template Details:**
- **Name**: `basic_otp`
- **Category**: AUTHENTICATION
- **Type**: Body + URL Button (Positional Parameters)
- **Components**:
  - Body: "*{{1}}* is your verification code. For your security, do not share this code."
  - Buttons: 1 URL button with OTP code ("Copy code")
- **Parameters**: 
  - `{{1}}` - OTP code (POSITIONAL)
- **Special Features**: Auto-populated button parameter with OTP code

**Chatwoot UI**

![Chatwoot Template Configuration](templates/basic_otp_chatwoot.png)

**WhatsApp Delivery**

![WhatsApp Delivered Message](templates/basic_otp_whatsapp.png)

### otp_verification

**Template Details:**
- **Name**: `otp_verification`
- **Category**: AUTHENTICATION
- **Type**: Body + URL Button (Positional Parameters)
- **Components**:
  - Body: "Use code *{{1}}* to verify your transaction of {{2}}."
  - Buttons: 1 URL button with OTP code ("Copy code")
- **Parameters**: 
  - `{{1}}` - OTP code (POSITIONAL)
  - `{{2}}` - Transaction amount (POSITIONAL)
- **Special Features**: Auto-populated button parameter with OTP code

**Chatwoot UI**

![Chatwoot Template Configuration](templates/otp_verification_chatwoot.png)

**WhatsApp Delivery**

![WhatsApp Delivered Message](templates/otp_verification_whatsapp.png)

### secure_login_otp

**Template Details:**
- **Name**: `secure_login_otp`
- **Category**: AUTHENTICATION
- **Type**: Body + Footer + URL Button (Positional Parameters)
- **Components**:
  - Body: "*{{1}}* is your verification code. For your security, do not share this code."
  - Footer: "This code expires in 10 minutes."
  - Buttons: 1 URL button with Zero-tap auto-fill ("Copy code")
- **Parameters**: 
  - `{{1}}` - OTP code (POSITIONAL)
- **Special Features**: Zero-tap auto-fill functionality, Auto-populated button parameter

**Chatwoot UI**

![Chatwoot Template Configuration](templates/secure_login_otp_chatwoot.png)

#### WhatsApp Delivery

![WhatsApp Delivered Message](templates/secure_login_otp_whatsapp.png)
