# Restrict content types served inline to prevent XSS via uploaded files.
# PDFs with embedded JavaScript can execute in-browser when served with
# Content-Disposition: inline. Force them to download instead.
Rails.application.config.active_storage.content_types_allowed_inline = %w[
  image/png
  image/gif
  image/jpeg
  image/tiff
  image/vnd.adobe.photoshop
  image/vnd.microsoft.icon
  image/webp
  image/avif
  image/heic
  image/heif
]
