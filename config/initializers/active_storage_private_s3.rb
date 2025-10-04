# Override ActiveStorage::Blob to always return direct S3 signed URLs
ActiveStorage::Blob.class_eval do
  def url(expires_in: ActiveStorage.service_urls_expire_in, disposition: :inline, filename: nil, **options)
    # For private S3 buckets, always return signed S3 URL directly
    service.url(key, 
      expires_in: expires_in, 
      disposition: disposition, 
      filename: filename || self.filename, 
      content_type: content_type,
      **options
    )
  end
end
