# Force direct signed S3 URLs for private buckets
Rails.application.configure do
  # Ensure we're using signed URLs for private S3 access
  config.active_storage.resolve_model_to_route = :rails_storage_proxy
end

# Override ActiveStorage::Blob to always use service URLs
ActiveStorage::Blob.class_eval do
  def url(expires_in: ActiveStorage.service_urls_expire_in, disposition: :inline, filename: nil, **options)
    # Always return signed S3 URL directly for private buckets
    service.url(key, 
      expires_in: expires_in, 
      disposition: disposition, 
      filename: filename, 
      content_type: content_type,
      **options
    )
  end
  
  # Override service_url to ensure consistent signed URL generation
  def service_url(expires_in: ActiveStorage.service_urls_expire_in, disposition: :inline, filename: nil, **options)
    service.url(key, 
      expires_in: expires_in, 
      disposition: disposition, 
      filename: filename || self.filename, 
      content_type: content_type,
      **options
    )
  end
end
