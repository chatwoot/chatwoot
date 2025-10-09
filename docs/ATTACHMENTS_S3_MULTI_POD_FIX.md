# Attachment & S3 Multi-Pod Kubernetes Fix Documentation

## Problem Statement

In multi-pod Kubernetes deployments with S3 storage, attachments were experiencing 404 errors intermittently:
- **Chat Window**: Images loaded sometimes but failed on other occasions
- **Download Button**: ALWAYS returned 404
- **Root Cause**: Rails Active Storage redirect URLs (`/rails/active_storage/blobs/redirect/...`) contain signed blob IDs that fail validation when requests hit different K8s pods than the one that generated the URL

## Solution Overview

Switch from Rails redirect URLs to direct S3 signed URLs, which are validated by S3 itself and work consistently across all pods.

---

## Backend Changes

### 1. Attachment Model (`app/models/attachment.rb`)

#### Added `download_thumb_url` Method (Lines 77-87)
```ruby
# Returns direct S3 signed URL for thumbnail (bypasses Rails redirect)
# Use this for multi-replica deployments where redirect URLs may fail
def download_thumb_url
  return '' unless file.attached? && file.representable?

  ActiveStorage::Current.url_options = Rails.application.routes.default_url_options if ActiveStorage::Current.url_options.blank?
  variant = file.representation(resize_to_fill: [250, nil])
  variant.processed.url
rescue ActiveStorage::FileNotFoundError
  ''
end
```

**Purpose**:
- Generates direct S3 signed URL for 250px width thumbnail
- Uses same resize logic as original `thumb_url` but returns direct URL
- Critical for multi-pod: bypasses Rails redirect mechanism

#### Enhanced `download_url` Method (Lines 60-67)
```ruby
def download_url
  return '' unless file.attached?

  ActiveStorage::Current.url_options = Rails.application.routes.default_url_options if ActiveStorage::Current.url_options.blank?
  file.blob.url
rescue ActiveStorage::FileNotFoundError
  ''
end
```

**Changes**:
- Added early return guard for unattached files
- Added `ActiveStorage::FileNotFoundError` exception handling
- Returns empty string for graceful degradation when S3 files are missing

#### Updated `file_metadata` Method (Lines 95-107)
```ruby
def file_metadata
  metadata = {
    extension: extension,
    data_url: download_url,      # Changed from: file_url
    thumb_url: download_thumb_url, # Changed from: thumb_url
    file_size: file.byte_size,
    width: file.metadata[:width],
    height: file.metadata[:height]
  }

  metadata[:data_url] = metadata[:thumb_url] = external_url if message.inbox.instagram? && message.incoming?
  metadata
end
```

**Impact**:
- API responses now return direct S3 URLs for both full images and thumbnails
- This is the key fix - all API consumers now get multi-pod compatible URLs

### 2. Active Storage Configuration

#### Initializer Override (`config/initializers/active_storage_private_s3.rb`)
```ruby
Rails.application.config.after_initialize do
  if defined?(ActiveStorage::Blob)
    ActiveStorage::Blob.class_eval do
      def url(expires_in: ActiveStorage.service_urls_expire_in, disposition: :inline, filename: nil, **options)
        service.url(key,
          expires_in: expires_in,
          disposition: disposition,
          filename: filename || self.filename,
          content_type: content_type,
          **options
        )
      end
    end
  end
end
```

**Purpose**:
- Overrides `ActiveStorage::Blob#url` to always return direct S3 signed URLs
- Includes original filename in `response-content-disposition` header
- Works for both `download_url` and `download_thumb_url` methods

#### Storage Configuration (`config/storage.yml`)
```yaml
amazon:
  service: S3
  access_key_id: <%= ENV.fetch('AWS_ACCESS_KEY_ID', '') %>
  secret_access_key: <%= ENV.fetch('AWS_SECRET_ACCESS_KEY', '') %>
  region: <%= ENV.fetch('AWS_REGION', '') %>
  bucket: <%= ENV.fetch('S3_BUCKET_NAME', '') %>
  upload:
    cache_control: <%= ENV.fetch('ACTIVE_STORAGE_CACHE_CONTROL', 'public, max-age=3600') %>
```

**Cache Configuration**:
- Default: `public, max-age=3600` (1 hour browser caching)
- Configurable via `ACTIVE_STORAGE_CACHE_CONTROL` environment variable
- Enables browser caching for better performance

---

## Frontend Changes

### 1. Dashboard Components

#### Image/Audio/Video Bubble (`app/javascript/dashboard/components/widgets/conversation/bubble/ImageAudioVideo.vue`)

**Added `thumbUrl` Computed Property (Lines 65-68)**:
```javascript
thumbUrl() {
  // Use thumbnail for preview, fallback to full image if thumb not available
  return this.attachment.thumb_url || this.attachment.data_url;
}
```

**Updated Template (Line 105)**:
```vue
<img
  v-if="isImage && !isImageError"
  class="bg-woot-200 dark:bg-woot-900"
  :src="thumbUrl"  <!-- Changed from: dataUrl -->
  :width="imageWidth"
  :height="imageHeight"
  @click="onClick"
  @error="onImgError"
/>
```

**Impact**:
- Message previews load thumbnails (~10-50KB) instead of full images (~500KB-5MB)
- Significantly faster initial load times
- Full images still available in gallery view on click

#### Gallery View (`app/javascript/dashboard/components/widgets/conversation/components/GalleryView.vue`)

**Refactored Filename Extraction (Lines 102-106)**:
```javascript
const fileNameFromDataUrl = computed(() => {
  const { data_url: dataUrl } = activeAttachment.value;
  const fileName = extractFilenameFromUrl(dataUrl);
  return fileName ? decodeURIComponent(fileName) : '';
});
```

**Purpose**: Delegates filename parsing to shared utility (see below)

### 2. Shared Utilities

#### File Helper (`app/javascript/shared/helpers/FileHelper.js`)

**Added `extractFilenameFromUrl` Function (Lines 23-58)**:
```javascript
/**
 * Extracts filename from URL, handling both Rails Active Storage URLs and S3 direct URLs
 * @param {string} url - The file URL (Rails redirect URL or S3 signed URL)
 * @returns {string} The extracted filename
 */
export const extractFilenameFromUrl = (url) => {
  if (!url) return '';

  try {
    // Check if URL has query parameters (S3 direct URL)
    if (url.includes('?')) {
      // Try to extract filename from response-content-disposition parameter
      const urlParams = new URLSearchParams(url.split('?')[1]);
      const disposition = urlParams.get('response-content-disposition');

      if (disposition) {
        // Extract filename from: inline; filename="IMG_4870.jpeg"
        const match = disposition.match(/filename[*]?=['"]?([^'";\s]+)['"]?/i);
        if (match && match[1]) {
          return match[1];
        }
      }

      // Fallback: strip query params and get last path segment
      const pathWithoutQuery = url.split('?')[0];
      return pathWithoutQuery.split('/').pop() || '';
    }

    // Old format (Rails Active Storage URL): extract filename from path
    return url.split('/').pop() || '';
  } catch (error) {
    // Fallback to simple extraction if parsing fails
    const pathWithoutQuery = url.split('?')[0];
    return pathWithoutQuery.split('/').pop() || '';
  }
};
```

**Features**:
- **Backward Compatible**: Handles both old Rails URLs and new S3 direct URLs
- **S3 Direct URLs**: Parses `response-content-disposition` parameter to extract actual filename
- **Rails URLs**: Extracts filename from URL path
- **Graceful Degradation**: Falls back to blob key if parsing fails
- **Regex Support**: Handles multiple filename formats (`filename="..."`, `filename*=UTF-8''...`, etc.)

### 3. Widget Components

#### Conversation Actions (`app/javascript/widget/store/modules/conversation/actions.js`)

**Updated Failed Attachment Handling (Lines 85-88)**:
```javascript
} catch (error) {
  commit('deleteMessage', tempMessage.id);
  // Failed attachment removed from UI
}
```

**Previous Behavior**:
```javascript
} catch (error) {
  commit('pushMessageToConversation', { ...tempMessage, status: 'failed' });
  commit('updateMessageMeta', {
    id: tempMessage.id,
    meta: { ...meta, error: '' },
  });
  // Show error
}
```

**Impact**:
- Failed uploads are removed from UI entirely instead of showing red error state
- Prevents misleading users into thinking attachment was sent
- Cleaner UX for retry scenarios

---

## URL Format Comparison

### Before (Rails Redirect URL)
```
/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBZ...
```
**Issues**:
- Signed blob ID validated by Rails server
- Fails across different K8s pods
- 404 errors in multi-replica deployments

### After (S3 Direct URL)
```
https://delta-devnet-chatwoot.s3.ap-northeast-1.amazonaws.com/sktyddbiscse0zpnt5wyz7g01lcp?
response-content-disposition=inline%3B%20filename%3D%22IMG_4870.jpeg%22&
response-content-type=image%2Fjpeg&
X-Amz-Algorithm=AWS4-HMAC-SHA256&
X-Amz-Credential=ASIA...%2F20251006%2Fap-northeast-1%2Fs3%2Faws4_request&
X-Amz-Date=20251006T181014Z&
X-Amz-Expires=3600&
X-Amz-Security-Token=IQoJb3JpZ...&
X-Amz-SignedHeaders=host&
X-Amz-Signature=9e1eb650b3d6446ee3e0d6dec35f307d60189783d7073c1d83e9de2491f41eea
```
**Benefits**:
- Signed by AWS S3, validated by S3
- Works consistently across all K8s pods
- No dependency on Rails server state

---

## Performance Benefits

### 1. Thumbnail Usage
- **Before**: Loading full images (500KB-5MB) for message previews
- **After**: Loading thumbnails (10-50KB) for message previews
- **Improvement**: 10-50x faster initial load times

### 2. Browser Caching
- S3 URLs include `Cache-Control: public, max-age=3600` header
- Browser caches thumbnails and full images for 1 hour
- Subsequent loads are instant from browser cache

### 3. Error Handling
- Graceful degradation when S3 files are missing (orphaned blob records)
- Returns empty string instead of crashing API
- Frontend handles missing images with error UI

---

## API Response Format

### Attachment Object Structure
```json
{
  "id": 123,
  "message_id": 456,
  "file_type": "image",
  "account_id": 1,
  "extension": "jpeg",
  "data_url": "https://bucket.s3.amazonaws.com/key?response-content-disposition=...",
  "thumb_url": "https://bucket.s3.amazonaws.com/variants/key/...?response-content-disposition=...",
  "file_size": 1024000,
  "width": 1920,
  "height": 1080
}
```

**Key Fields**:
- `data_url`: Direct S3 URL for full image (used for downloads and gallery view)
- `thumb_url`: Direct S3 URL for 250px thumbnail (used for message previews)

---

## Deployment Considerations

### Environment Variables Required
```bash
# AWS S3 Configuration
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=ap-northeast-1
S3_BUCKET_NAME=your-bucket-name

# Optional: Cache Control (default: public, max-age=3600)
ACTIVE_STORAGE_CACHE_CONTROL=public, max-age=3600

# Direct Uploads (required for widget uploads)
DIRECT_UPLOADS_ENABLED=true
```

### S3 Bucket Configuration
- **CORS**: Must allow direct uploads from your domain
- **Bucket Policy**: Must allow `s3:GetObject` for signed URLs
- **IAM Permissions**: Rails app needs `s3:PutObject` and `s3:GetObject`

### Kubernetes Considerations
- Works seamlessly with multiple replicas (2+)
- No session affinity required
- No shared storage needed across pods

---

## Testing

### Manual Testing Checklist
- [ ] Upload attachment via widget
- [ ] Verify thumbnail loads in message list (dashboard)
- [ ] Click image to open gallery view
- [ ] Download image using download button
- [ ] Reload page and verify image still loads
- [ ] Test across different K8s pods (if possible)
- [ ] Test failed upload scenario in widget
- [ ] Verify filename displays correctly in gallery header

### Edge Cases Handled
1. **Missing S3 Files**: Returns empty string, UI shows error
2. **Failed Widget Uploads**: Message removed from UI entirely
3. **Legacy URLs**: Backward compatible with old Rails redirect URLs
4. **Instagram Attachments**: Still uses `external_url` for incoming messages

---

## Rollback Plan

If issues occur, revert these changes:

### Backend
```ruby
# In app/models/attachment.rb file_metadata method
data_url: file_url,      # Revert to Rails redirect URL
thumb_url: thumb_url,    # Revert to Rails redirect URL
```

### Frontend
```javascript
// In ImageAudioVideo.vue template
:src="dataUrl"  // Revert to full image

// In FileHelper.js
return url.split('/').pop() || '';  // Simple extraction only
```

---

## Related Files Changed

### Backend
- `app/models/attachment.rb`
- `config/initializers/active_storage_private_s3.rb`
- `config/storage.yml` (configuration only)

### Frontend
- `app/javascript/dashboard/components/widgets/conversation/bubble/ImageAudioVideo.vue`
- `app/javascript/dashboard/components/widgets/conversation/components/GalleryView.vue`
- `app/javascript/shared/helpers/FileHelper.js`
- `app/javascript/widget/store/modules/conversation/actions.js`

---

## Monitoring & Observability

### Metrics to Watch
- **404 Rate**: Should drop to near zero for attachment URLs
- **Image Load Time**: Should improve by 10-50x for message previews
- **Widget Upload Success Rate**: No change expected
- **S3 API Calls**: Slight increase (thumbnail generation)

### Logs to Monitor
- `ActiveStorage::FileNotFoundError` - indicates orphaned blob records
- Widget upload failures - should be silent (message removed)

---

## Future Improvements

### Potential Enhancements
1. **Add Filename to API Response**: Store original filename in `attachments` table to avoid URL parsing
2. **Progressive Image Loading**: Use blur-up technique with tiny placeholder
3. **WebP Support**: Generate WebP variants for modern browsers
4. **CDN Integration**: Put CloudFront or CloudFlare in front of S3
5. **Longer Cache TTL**: Increase to 1 week for immutable attachments

### Known Limitations
1. **Thumbnail Generation**: First load generates thumbnail (1-2 second delay)
2. **URL Expiry**: S3 signed URLs expire after 1 hour (configurable)
3. **No Lazy Loading**: All message images load on scroll (could be optimized)

---

## References

- [Rails Active Storage Documentation](https://edgeguides.rubyonrails.org/active_storage_overview.html)
- [AWS S3 Signed URLs](https://docs.aws.amazon.com/AmazonS3/latest/userguide/ShareObjectPreSignedURL.html)
- [Chatwoot Storage Configuration](https://developers.chatwoot.com/self-hosted/configuration/environment-variables#configure-storage)

---

**Last Updated**: 2025-10-06
**Authors**: Delta Team
**Status**: Production Ready
