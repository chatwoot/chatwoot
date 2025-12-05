# Chatwoot Issue: PDF File Upload Failure to WhatsApp Channel

> **⚠️ SUPERSEDED**: This was the initial bug report draft. For the complete diagnosis and fix, see [ISSUE-002-PDF-UPLOAD-MULTIPART-FIX.md](./ISSUE-002-PDF-UPLOAD-MULTIPART-FIX.md)
>
> **Status**: ✅ RESOLVED - 2025-10-30
> **Fix**: Updated `send_file_message` to use multipart/form-data upload instead of JSON with file_url

---

**Target Project**: [chatwoot/chatwoot](https://github.com/chatwoot/chatwoot)
**Issue Type**: Bug Report
**Severity**: High (PDF uploads completely broken for WhatsApp channel)
**Affected Component**: WhatsApp Channel Integration - File Attachments
**Chatwoot Version**: Unknown (to be filled in when submitting)
**Date Identified**: 2025-10-30

---

## Issue Summary

PDF file attachments fail to send through the WhatsApp channel in Chatwoot with the error:

```
[WHATSAPP WEB] Message send failed - Code: INTERNAL_SERVER_ERROR
Message: request Content-Type has bad boundary or is not multipart/form-data
```

**Important**: Images, videos, and audio files send successfully. Only PDF/document files (`file_type: "file"`) fail.

---

## Expected Behavior

When a user uploads a PDF file in a Chatwoot conversation using the WhatsApp channel, Chatwoot should:

1. Store the PDF file attachment
2. Download the file from ActiveStorage
3. Create a proper `multipart/form-data` request
4. POST to the WhatsApp API endpoint `/send/file` with:
   - Form field `phone`: recipient phone number
   - Form field `file`: the PDF file binary
   - Form field `caption`: optional message caption
5. Receive a success response
6. Display the sent file in the conversation

---

## Actual Behavior

When sending a PDF file:

1. ✅ Chatwoot successfully creates the message with attachment
2. ✅ Attachment is stored in ActiveStorage with correct metadata
3. ❌ `SendReplyJob` fails when POSTing to WhatsApp API
4. ❌ Error: "request Content-Type has bad boundary or is not multipart/form-data"
5. ❌ File is not sent to WhatsApp
6. ❌ User sees message failed or no confirmation

**Working file types**:
- ✅ Images (JPG, PNG, etc.) - `file_type: "image"`
- ✅ Videos (MP4, etc.) - `file_type: "video"`
- ✅ Audio files (MP3, etc.) - `file_type: "audio"`

**Failing file types**:
- ❌ PDF documents - `file_type: "file"`
- ❌ Other document types (DOC, XLS, etc.) - presumably affected

---

## Steps to Reproduce

### Prerequisites
- Chatwoot instance with WhatsApp channel configured
- WhatsApp channel using go-whatsapp-web-multidevice API (or similar)
- Authenticated WhatsApp connection

### Steps
1. Open a Chatwoot conversation on WhatsApp channel
2. Click the attachment button
3. Select and upload a PDF file (e.g., `document.pdf`, 300KB)
4. Add optional message text
5. Click Send

### Expected Result
- File is sent to WhatsApp contact
- File appears in WhatsApp conversation
- Message shows as "sent" in Chatwoot

### Actual Result
- Error in Sidekiq logs: `[WHATSAPP WEB] Message send failed`
- Message may show as failed or stuck in "sending" state
- File is not delivered to WhatsApp contact

---

## Error Logs

### Chatwoot Sidekiq Logs

```
2025-10-30T11:08:29.924Z pid=14151 tid=10bz class=ActionCableBroadcastJob jid=bcc77927ece85216626ae3ef INFO: start

2025-10-30T11:08:29.926Z pid=14151 tid=10bz class=ActionCableBroadcastJob jid=bcc77927ece85216626ae3ef INFO:
Performing ActionCableBroadcastJob (Job ID: 15f68b92-e6ba-401a-80cc-a67a48462043) from Sidekiq(critical)
enqueued at 2025-10-30T11:08:29.923057000Z with arguments:
["LbsqUWpBmMjhpuyJSfUmGx4g", "rHogg7CwvznGV2jULhzC4X2h"], "message.created",
{
  id: 12,
  content: nil,
  content_type: "text",
  attachments: [{
    id: 3,
    message_id: 12,
    file_type: "file",           # <-- Note: "file" not "image" or "video"
    account_id: 1,
    extension: nil,              # <-- Extension is nil
    data_url: "http://0.0.0.0:3000/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBDUT09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--54b536d6b86ad7c088736849732cea2f44114d6d/850250593750.pdf",
    thumb_url: "",
    file_size: 308482,           # <-- 308KB PDF
    width: nil,
    height: nil
  }]
}

2025-10-30T11:08:32.241Z pid=14151 tid=1093 class=SendReplyJob jid=477dd75ce05f6eb5172436b2 INFO: start

2025-10-30T11:08:32.243Z pid=14151 tid=1093 class=SendReplyJob jid=477dd75ce05f6eb5172436b2 INFO:
Performing SendReplyJob (Job ID: e76d47af-5ed8-4537-aecd-95c31082009d)
from Sidekiq(high) enqueued at 2025-10-30T11:08:30.110826000Z with arguments: 12

2025-10-30T11:08:32.263Z pid=14151 tid=1093 class=SendReplyJob jid=477dd75ce05f6eb5172436b2 ERROR:
[WHATSAPP WEB] Message send failed -
Code: INTERNAL_SERVER_ERROR,
Message: request Content-Type has bad boundary or is not multipart/form-data,
Full response: {
  "code" => "INTERNAL_SERVER_ERROR",
  "message" => "request Content-Type has bad boundary or is not multipart/form-data"
}

2025-10-30T11:08:32.263Z pid=14151 tid=1093 class=SendReplyJob jid=477dd75ce05f6eb5172436b2 INFO:
Performed SendReplyJob (Job ID: e76d47af-5ed8-4537-aecd-95c31082009d)
from Sidekiq(high) in 19.92ms

2025-10-30T11:08:32.263Z pid=14151 tid=1093 class=SendReplyJob jid=477dd75ce05f6eb5172436b2 elapsed=0.023 INFO: done
```

### WhatsApp API Logs (go-whatsapp-web-multidevice)

```
ERRO[0037] Panic recovered in middleware: request Content-Type has bad boundary or is not multipart/form-data
```

---

## Root Cause Analysis

### Hypothesis

Chatwoot's `SendReplyJob` is constructing the HTTP multipart/form-data request **incorrectly for PDF files** compared to image/video files.

**Evidence**:
1. ✅ Images and videos work → multipart request is constructed correctly for those file types
2. ❌ PDFs fail → multipart request is malformed for `file_type: "file"`
3. The WhatsApp API rejects the request before even processing it → malformed Content-Type header or boundary

### Likely Causes

**Option 1: Different HTTP client behavior for different file types**
- Chatwoot may use different code paths for `file_type: "file"` vs `file_type: "image"`
- The file attachment code might not set the Content-Type header correctly for PDFs

**Option 2: File download/read issue**
- Chatwoot might not be downloading the PDF from ActiveStorage correctly
- The file might be empty or corrupted when constructing the multipart form

**Option 3: Multipart boundary generation issue**
- The multipart form boundary might not be properly set in the Content-Type header
- Example: `Content-Type: multipart/form-data; boundary=----WebKitFormBoundary...`
- If the boundary is missing or malformed, the API will reject it

**Option 4: Missing or incorrect form field name**
- WhatsApp API expects form field named `file` (not `document` or `attachment`)
- Chatwoot might be using different field names for different file types

---

## Comparison: Working (Image) vs Failing (PDF)

### What Works (Image Upload)

**Expected HTTP Request**:
```http
POST /send/image HTTP/1.1
Host: whatsapp-api.example.com
Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryXYZ123

------WebKitFormBoundaryXYZ123
Content-Disposition: form-data; name="phone"

5521998762522
------WebKitFormBoundaryXYZ123
Content-Disposition: form-data; name="image"; filename="photo.jpg"
Content-Type: image/jpeg

[BINARY IMAGE DATA]
------WebKitFormBoundaryXYZ123--
```

**Result**: ✅ Success

### What Fails (PDF Upload)

**Expected HTTP Request**:
```http
POST /send/file HTTP/1.1
Host: whatsapp-api.example.com
Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryABC789

------WebKitFormBoundaryABC789
Content-Disposition: form-data; name="phone"

5521998762522
------WebKitFormBoundaryABC789
Content-Disposition: form-data; name="file"; filename="document.pdf"
Content-Type: application/pdf

[BINARY PDF DATA]
------WebKitFormBoundaryABC789--
```

**Actual HTTP Request** (suspected):
```http
POST /send/file HTTP/1.1
Host: whatsapp-api.example.com
Content-Type: multipart/form-data    # <-- Missing boundary?
# OR
Content-Type: application/json       # <-- Wrong Content-Type?
# OR
Content-Type: multipart/form-data; boundary=   # <-- Empty boundary?

[MALFORMED OR MISSING MULTIPART DATA]
```

**Result**: ❌ Error - "bad boundary or is not multipart/form-data"

---

## Code to Investigate (Chatwoot)

### Files Likely Involved

1. **WhatsApp Channel Integration**:
   - `app/models/channel/whatsapp.rb` (or similar)
   - WhatsApp-specific message sending logic

2. **SendReplyJob**:
   - `app/jobs/send_reply_job.rb` (or similar)
   - Job that sends messages to external APIs

3. **Attachment Handling**:
   - `app/models/attachment.rb`
   - How attachments are read and prepared for sending

4. **HTTP Client**:
   - Wherever HTTParty, Faraday, or RestClient is used for WhatsApp API calls
   - Check how multipart forms are constructed

### Suggested Investigation

**Look for differences in code paths**:

```ruby
# Pseudocode - where might the difference be?

case attachment.file_type
when 'image'
  send_image(attachment)  # This works ✅
when 'video'
  send_video(attachment)  # This works ✅
when 'audio'
  send_audio(attachment)  # This works ✅
when 'file'
  send_file(attachment)   # This fails ❌ - What's different here?
end
```

**Check HTTP client configuration**:

```ruby
# Is the multipart form constructed differently?

# Working (image):
HTTP.post(url, form: {
  phone: phone_number,
  image: HTTP::FormData::File.new(image_path)  # Correct
})

# Failing (PDF):
HTTP.post(url, form: {
  phone: phone_number,
  file: file_data  # Wrong? Should be HTTP::FormData::File?
})
# OR
HTTP.post(url, body: { ... }.to_json)  # Wrong Content-Type entirely?
```

---

## Debugging Information Needed

To help debug this issue, please provide:

1. **Code snippet** of how `SendReplyJob` sends file attachments to WhatsApp API
2. **HTTP request logs** showing:
   - Full headers (especially `Content-Type`)
   - Request body structure for both working (image) and failing (PDF) cases
3. **ActiveStorage configuration** - how files are downloaded before sending
4. **HTTP client library** used (HTTParty, Faraday, etc.) and version
5. **Chatwoot version** where this occurs

### How to Capture HTTP Request

**Option 1: Add logging to SendReplyJob**:
```ruby
# In SendReplyJob or WhatsApp message sender
Rails.logger.debug "HTTP Request Headers: #{request.headers.inspect}"
Rails.logger.debug "HTTP Request Body: #{request.body.inspect}"
```

**Option 2: Use HTTP debugging proxy**:
```bash
# Route Chatwoot API calls through mitmproxy
export HTTP_PROXY=http://localhost:8080
export HTTPS_PROXY=http://localhost:8080
```

**Option 3: Enable HTTParty/Faraday debugging**:
```ruby
# In initializer or configuration
HTTParty::Logger.new($stdout, :debug)
# OR
Faraday.new do |f|
  f.response :logger
end
```

---

## Workaround (Temporary)

Until this is fixed in Chatwoot, users can:

**Option 1**: Send PDFs via external link
- Upload PDF to external storage (Google Drive, Dropbox, etc.)
- Send the link in WhatsApp message
- Not ideal, requires extra steps

**Option 2**: Send PDFs manually
- Download the PDF from Chatwoot
- Send it manually via WhatsApp Web/Mobile
- Defeats the purpose of integration

**Option 3**: Convert PDFs to images (not recommended)
- Convert PDF to image format
- Upload as image instead of file
- Quality loss, poor user experience

---

## Proposed Fix (Chatwoot Team)

### Fix 1: Ensure Correct Content-Type Header

**Ensure the multipart boundary is properly set**:

```ruby
# When constructing HTTP request for file upload
HTTP.post(
  "#{api_url}/send/file",
  form: {
    phone: phone_number,
    file: HTTP::FormData::File.new(file_path, content_type: 'application/pdf'),
    caption: caption
  }
)
```

The HTTP client should automatically set:
```
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary...
```

### Fix 2: Use Same Code Path for All File Types

**Unify file sending logic**:

```ruby
def send_attachment(attachment)
  file_param_name = case attachment.file_type
    when 'image' then 'image'
    when 'video' then 'video'
    when 'audio' then 'audio'
    when 'file' then 'file'
  end

  # Use the same HTTP client method for all types
  send_multipart_file(
    endpoint: "/send/#{file_param_name}",
    param_name: file_param_name,
    file: attachment.download,  # Ensure file is downloaded correctly
    phone: contact.phone_number
  )
end
```

### Fix 3: Add Debugging and Error Handling

```ruby
begin
  response = send_file_to_whatsapp(attachment)
rescue HTTP::Error => e
  Rails.logger.error "WhatsApp file send failed"
  Rails.logger.error "Request headers: #{e.request.headers}"
  Rails.logger.error "Request body: #{e.request.body}"
  Rails.logger.error "Response: #{e.response.body}"
  raise
end
```

---

## Testing Checklist

After implementing a fix, verify:

- [ ] PDF files upload successfully to WhatsApp
- [ ] PDF filename is preserved
- [ ] PDF file size is correct (no corruption)
- [ ] PDF is downloadable from WhatsApp
- [ ] Images still work (no regression)
- [ ] Videos still work (no regression)
- [ ] Audio files still work (no regression)
- [ ] Large PDFs (>1MB) work
- [ ] Small PDFs (<100KB) work
- [ ] PDFs with special characters in filename work
- [ ] Multiple PDFs can be sent in succession

---

## Additional Context

### Environment

- **Chatwoot Version**: [Please fill in]
- **WhatsApp API**: go-whatsapp-web-multidevice (or specify your provider)
- **Ruby Version**: [Please fill in]
- **Rails Version**: [Please fill in]
- **HTTP Client**: [HTTParty/Faraday/RestClient - please fill in]

### Related Issues

- Search Chatwoot issues for "WhatsApp file upload"
- Search for "multipart/form-data" issues
- Check if this affects other channel types (Telegram, etc.)

### Screenshots

*If applicable, add screenshots showing:*
- The failed message in Chatwoot UI
- Sidekiq error logs
- Network tab showing the failed HTTP request

---

## Impact Assessment

**Severity**: High

**Users Affected**: All Chatwoot users using WhatsApp channel who need to send PDF documents

**Business Impact**:
- 🔴 Cannot send important documents (contracts, invoices, reports) via WhatsApp
- 🔴 Users must use workarounds (external links, manual sending)
- 🟡 Reduces value proposition of Chatwoot+WhatsApp integration
- 🟡 May cause users to switch to alternative solutions

**Technical Impact**:
- Likely a simple fix (correct multipart form construction)
- Low risk of side effects if fixed properly
- Should be testable with existing Chatwoot test infrastructure

---

## Suggested Labels for GitHub Issue

- `bug`
- `channel::whatsapp`
- `priority::high`
- `area::integrations`
- `good-first-issue` (if the fix is straightforward)

---

**Report Created**: 2025-10-30
**Reporter**: [Your name/handle]
**Chatwoot Installation**: Self-hosted / Cloud (specify)
**WhatsApp Provider**: go-whatsapp-web-multidevice v7.7.1

---

## How to Submit This Issue

1. Go to https://github.com/chatwoot/chatwoot/issues
2. Click "New Issue"
3. Select "Bug Report" template
4. Copy relevant sections from this report
5. Fill in your environment details
6. Add any additional logs or screenshots
7. Submit the issue

**Title Suggestion**:
```
[WhatsApp Channel] PDF file uploads fail with "bad boundary or is not multipart/form-data" error
```
