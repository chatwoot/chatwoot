# Backport of the Rails 8.0.5.2 fix for GHSA-v924-7rp8-4mxh (rails/rails@8106938), which has no
# 7.2 release. Remove once on Rails >= 8.0.5.2.
#
# `Blob#open` names its tempfile with the uploaded filename's extension and hands that path to
# ffprobe (VideoAnalyzer, AudioAnalyzer) and libvips (ImageAnalyzer::Vips) on attach. Those tools
# pick a decoder from the extension when the bytes do not identify their own format, so whoever
# uploads a file (a contact through the widget or a channel) chooses which decoder runs on it.
# The fix keeps the extension only when Marcel maps it to the blob's own content type.
module ActiveStorageBlobTempfileExtension
  def open(tmpdir: nil, &)
    service.open(
      key,
      checksum: checksum,
      verify: !composed,
      name: ["ActiveStorage-#{id}-", tempfile_extension],
      tmpdir: tmpdir,
      &
    )
  end

  private

  def tempfile_extension
    extension = filename.extension_with_delimiter
    return '' if extension.blank?

    type_for_extension = Marcel::MimeType.for(name: filename.to_s)
    return '' if type_for_extension == Marcel::MimeType::BINARY || type_for_extension != tempfile_media_type

    extension
  end

  # Marcel answers in canonical lowercase, so drop parameters and case before comparing.
  def tempfile_media_type
    content_type.to_s.split(';').first.to_s.strip.downcase
  end
end

ActiveSupport.on_load(:active_storage_blob) do
  prepend(ActiveStorageBlobTempfileExtension) unless self < ActiveStorageBlobTempfileExtension
end
