# WhatsApp Templates in Chatwoot

Chatwoot supports WhatsApp message templates for outbound messaging via the WhatsApp Business Platform.

📘 **Reference**: Meta Docs – [Message Templates](https://developers.facebook.com/docs/whatsapp/business-management-api/message-templates)

## Overview

WhatsApp Business API requires pre-approved message templates for initiating conversations with customers. Chatwoot provides support for creating and sending various types of templates while maintaining compliance with WhatsApp's template policies.

## ✅ What is Supported

### Template Categories

- **UTILITY** - Transactional messages (order confirmations, receipts, etc.)
- **MARKETING** - Promotional content and offers
- **AUTHENTICATION** - OTP codes and verification messages with automatic button parameter population
- **SHIPPING_UPDATE** - Package and delivery status updates
- **TICKET_UPDATE** - Support ticket notifications
- **ISSUE_RESOLUTION** - Customer service follow-ups

### Template Components

#### Headers

- **TEXT** - Plain text headers with variable placeholders ({{1}}, {{2}}, etc.)
- **IMAGE** - Image headers with media URL parameters (JPEG, PNG)
- **VIDEO** - Video headers with media URL parameters (MP4, 3GPP)
- **DOCUMENT** - Document headers with file URL parameters (PDF, DOC, DOCX, XLS, XLSX, PPT, PPTX, TXT)
- **None** - Templates without headers

#### Body (Required)

- **TEXT** - Always required component that supports:
  - Static text content
  - Variable placeholders ({{1}}, {{2}}, etc.)
  - Special authentication parameters (OTP codes, expiry times)
  - Rich text formatting preservation

#### Footer (Optional)

- **TEXT** - Plain text footers with variable support

#### Buttons (Optional)

- **URL** - Call-to-action buttons with dynamic URLs and variable parameters
- **PHONE_NUMBER** - Click-to-call buttons
- **COPY_CODE** - Coupon/discount code buttons (max 15 characters)
- **QUICK_REPLY** - Interactive reply buttons for user responses

### Special Template Types

#### Authentication Templates

- **OTP Templates**: Automatic OTP code and expiry time parameter handling
- **Button Auto-population**: URL buttons automatically populated with OTP codes
- **Enhanced Validation**: OTP codes (4-8 digits), expiry times validation
- **Structured Parameters**: Organized body and button parameter processing

#### Media Templates

- **Image Templates**: Full support for JPEG, PNG formats with URL validation
- **Video Templates**: Full support for MP4, 3GPP formats with URL validation
- **Document Templates**: **NEW** - Full support for PDF, Office documents, and text files
- **URL Validation**: Comprehensive validation, sanitization, and accessibility checks
- **Media Parameter Building**: Proper WhatsApp API format generation

## 🔄 Supported Template Combinations

### Basic Templates

1. **Text Only**: Body component only
2. **Text + Footer**: Body with footer text
3. **Text Header + Body**: Text header with body content
4. **Text Header + Body + Footer**: Full text template with all components

### Media Templates

5. **Image Header + Body**: Image with descriptive text
6. **Image Header + Body + Footer**: Image template with footer
7. **Video Header + Body**: Video with descriptive text
8. **Document Header + Body**: **NEW** - Document with description (PDFs, Office docs, etc.)
9. **Media + Buttons**: Any media header with action buttons

### Button Templates

10. **Body + URL Button**: Text with call-to-action and dynamic URLs
11. **Body + Phone Button**: Text with click-to-call
12. **Body + Copy Code**: Text with coupon code validation
13. **Body + Quick Reply Button**: Text with interactive reply buttons
14. **Authentication + URL Button**: OTP templates with auto-populated button parameters

### Authentication Templates

15. **OTP Template**: Body with OTP code and expiry with enhanced processing
16. **OTP + Footer**: OTP template with footer text
17. **OTP + URL Buttons**: **NEW** - OTP template with auto-populated action buttons

## ❌ What is Not Supported

### Interactive Components

- **LIST** templates with selectable options
- **PRODUCT** templates with catalog integration
- **CATALOG** templates for product browsing
- **Multi-select** components

### Location Components

- **LOCATION** headers with map coordinates
- **Address** parameters with latitude/longitude
- **Location-based** templates

### Advanced Features

- **Rich text formatting** in template creation (preserved in sending)
- **Carousel** templates with multiple cards
- **Form** components for data collection
- **Payment** integration templates
- **Flow** templates with conditional logic

### Limitations

- **Button limit**: Maximum 3 buttons per template
- **Variable limit**: Maximum 10 variables per component
- **Character limits**: Per WhatsApp Business API restrictions
- **Media size limits**: Documents < 100MB, Images < 5MB, Videos < 16MB

## 🚀 Using Templates in Chatwoot

### Template Creation

1. Create templates through WhatsApp Business Manager
2. Ensure templates are in **approved** status
3. Templates will automatically/manually sync to Chatwoot
4. Unsupported template types are automatically filtered out

### Sending Templates

#### Legacy Template Interface (Current)

1. **Select Template**: Choose from approved templates in the picker
2. **Fill Parameters**:
   - **Media URLs**: For image/video/document headers (must be publicly accessible)
   - **Body Variables**: Text values for {{1}}, {{2}}, etc. placeholders
   - **Button Parameters**: Dynamic values for URL buttons and copy codes
   - **Authentication Values**: OTP codes with automatic validation

### Parameter Validation & Processing

#### Frontend Processing

- **Variable Detection**: Automatic parsing of {{}} placeholders
- **Parameter Organization**: Structured grouping by component type
- **Validation Rules**: Real-time validation with user feedback
- **Special Handling**: Authentication template auto-population

#### Backend Processing

- **Enhanced Template Processing**: Handles structured parameter format
- **Media Parameter Building**: Generates proper WhatsApp API media objects
- **Authentication Support**: Auto-populates button parameters with OTP values
- **URL Validation**: Comprehensive accessibility and format checking

## 🔧 Technical Implementation

### Frontend Architecture

#### Components

- **TemplatesPicker.vue**: Template selection with filtering for supported types
- **TemplateParser.vue**: **Enhanced** - Parameter input with structured processing
  - Media URL input for IMAGE/VIDEO/DOCUMENT headers
  - Body parameter handling with authentication special cases
  - Button parameter processing with auto-population
  - Enhanced validation and error handling

#### TODO: 
- Add support all the advanced template types for new Conversation templates
- Add support for all the advanced template types for WhatsApp Campaigns

### Backend Architecture

#### Core Service

- **TemplateProcessorService**: Main processing engine with multiple pathways:
  - **Enhanced Processing**: For structured parameters (header/body/buttons)
  - **Legacy Processing**: For simple text-only templates
  - **Authentication Processing**: Special handling for OTP templates
  - **Media Processing**: Dedicated handling for IMAGE/VIDEO/DOCUMENT templates

#### Processing Flow

```ruby
# 1. Parameter Routing
if structured_params?(header/body/buttons)
  process_enhanced_template_params()
else
  # Legacy processing for simple templates
  process_legacy_template_params()
end

2. Component Building
- Header: Media parameter generation
- Body: Text parameter processing
- Buttons: URL/copy_code parameter handling

3. WhatsApp API Formatting
Convert to proper WhatsApp Cloud API structure
```

#### Media Parameter Handling

- **URL Validation**: Scheme, accessibility, format checking
- **Media Type Detection**: Automatic format detection and validation
- **Parameter Building**: Generates proper WhatsApp media objects
- **Error Handling**: Comprehensive validation with helpful error messages

### API Integration

- **WhatsApp Cloud API**: Primary integration for template sending
- **Template Sync**: Automatic synchronization of approved templates with filtering
- **Parameter Formatting**: Converts Chatwoot structured parameters to WhatsApp format
- **Error Handling**: Validates parameters and provides detailed error feedback

## 📋 Best Practices

### Template Design

- Keep message content **clear and concise**
- Use **meaningful variable names** for better organization
- Test templates thoroughly before approval
- Follow WhatsApp's **template policies** and guidelines

### Parameter Management

- **Media URLs**: Use publicly accessible URLs (avoid temporary/auth-required URLs)
  - ✅ `https://your-domain.com/files/document.pdf`
  - ❌ `https://scontent.whatsapp.net/...` (temporary WhatsApp URLs)
- **Authentication Templates**: Let system auto-populate button parameters
- **Validation**: Always validate parameters before sending
- **Error Handling**: Implement proper error handling for failed parameters

### Media Best Practices

- **Documents**: Use direct download URLs, ensure < 100MB file size
- **Images**: Optimize for mobile viewing, ensure < 5MB file size
- **Videos**: Keep under 16MB, use MP4 format for best compatibility
- **Accessibility**: Ensure all media URLs are publicly accessible without authentication

### Compliance

- Ensure all templates are **properly approved** before use
- Follow **opt-in requirements** for marketing templates
- Respect **rate limits** and sending windows
- Monitor **template quality ratings** and compliance metrics

## 🆘 Troubleshooting

### Common Issues

#### Template Issues

- **Template not appearing**: Check approval status and supported format
- **Interactive templates missing**: LIST/PRODUCT/CATALOG templates are not supported
- **Location templates missing**: LOCATION templates are not supported

#### Parameter Issues

- **Parameter validation errors**: Verify required fields are filled
- **Media loading failures**: Ensure URLs are publicly accessible and valid format
- **Button parameters empty**: Check auto-population for authentication templates

#### Sending Failures

- **Format mismatch errors**: Verify template structure matches expected format
- **Media upload errors (131053)**: Check media URL accessibility and file size
- **Missing parameter errors**: Ensure all required template variables are filled

### Error Messages & Solutions

#### Media Errors

- `Media upload error (131053)`:
  - **Cause**: URL not accessible, file too large, or unsupported format
  - **Solution**: Use publicly accessible URLs, check file size limits

#### Parameter Errors

- `Required parameter is missing`:
  - **Cause**: Template variables not filled or button parameters missing
  - **Solution**: Fill all required fields, check authentication auto-population

#### Template Errors

- `Template not found`: Template may not be approved or synced
- `Invalid parameter format`: Check variable formatting and requirements
- `OTP validation failed`: Ensure OTP is 4-8 digits numeric only

### Debugging Support

- Check WhatsApp Business Manager for template approval status
- Verify template compliance with supported component types
- Review parameter structure and validation requirements
- Check media URL accessibility independently
- Monitor Rails logs for detailed error information

## 📈 Future Roadmap & TODOs

### Future Enhancements

While Chatwoot currently provides comprehensive core template functionality, potential future improvements include:

- **Rich text formatting** support in template creation
- **Enhanced media validation** with format conversion
- **Template performance analytics** and usage metrics
- **Advanced parameter management** with preset values
- **Custom template validation rules** and business logic
- **Template testing environment** for development
- **Media asset management** with CDN integration

### Integration Improvements

- **Webhook support** for template status changes
- **Advanced error handling** with retry mechanisms
- **Template versioning** and rollback capabilities
- **Multi-language template** management
- **Template approval workflow** integration

## ⚠️ Known Limitations

### Dynamic URL Button Issues

Currently, there are known issues with dynamic URL buttons in certain templates due to WhatsApp Business Manager generating malformed URL structures with mixed parameter formats. **Workaround**: Use static URLs in your button templates instead of dynamic parameters for reliable functionality.

### QA Checklist

**Complete Template Coverage: 16 Templates covering all 17 Supported Combinations**

| Template Name | Category | Header | Buttons | Template Type | Coverage |
| --- | --- | --- | --- | --- | --- |
| greet | MARKETING | None | None | Text Only | ✅ |
| delivery_confirmation | UTILITY | None | None | Text Only | ✅ |
| hello_world | UTILITY | TEXT | None | Text Header + Body + Footer | ✅ |
| address_update | UTILITY | TEXT | None | Text Header + Body | ✅ |
| order_confirmation | MARKETING | IMAGE | None | Image Header + Body | ✅ |
| product_launch | MARKETING | IMAGE | None | Image Header + Body + Footer | ✅ |
| training_video | MARKETING | VIDEO | None | Video Header + Body | ✅ |
| purchase_receipt | UTILITY | DOCUMENT | None | Document Header + Body | ✅ |
| event_invitation_static | MARKETING | None | URL, URL | Body + Static URL Buttons | ✅ |
| feedback_request | MARKETING | None | URL | Body + URL Button | ✅ |
| support_callback | UTILITY | None | PHONE_NUMBER | Body + Phone Button | ✅ |
| discount_coupon | MARKETING | None | COPY_CODE | Body + Copy Code | ✅ |
| technician_visit | UTILITY | TEXT | QUICK_REPLY, QUICK_REPLY | Body + Quick Reply Button | ✅ |
| basic_otp | AUTHENTICATION | None | URL (Copy Code) | Basic OTP Template | ✅ |
| otp_verification | AUTHENTICATION | None | URL (Copy Code) | Authentication + URL Button | ✅ |
| secure_login_otp | AUTHENTICATION | None | URL (Zero-tap) | OTP + Footer + Zero-tap | ✅ |

**Summary:**
- **Total Templates**: 16
- **Template Combinations Covered**: 17/17 (100%)
- **Authentication Methods**: Copy Code, Zero-tap Auto-fill
- **Media Types**: TEXT, IMAGE, VIDEO, DOCUMENT
- **Button Types**: URL, PHONE_NUMBER, COPY_CODE, QUICK_REPLY
- **Parameter Formats**: NAMED, POSITIONAL