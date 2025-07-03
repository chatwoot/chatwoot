module Captain::Tools::PdfExtractionService::BlobHandler
  private

  def active_storage_blob_url?
    pdf_source.include?('/rails/active_storage/blobs/') ||
      (pdf_source.include?('blob') && pdf_source.include?('pdf'))
  end

  def extract_from_active_storage_blob
    blob = find_blob_from_url
    return extract_blob_content(blob) if blob

    Rails.logger.warn 'ActiveStorage blob not found, falling back to URL download'
    extract_from_url
  end

  def extract_blob_content(blob)
    blob.open { |file| extract_from_file(file.path) }
  end

  def find_blob_from_url
    blob_key = extract_blob_key_from_url
    return nil if blob_key.blank?

    ActiveStorage::Blob.find_by(key: blob_key)
  rescue StandardError => e
    Rails.logger.error "Error finding blob with key '#{blob_key}': #{e.message}"
    nil
  end

  def extract_blob_key_from_url
    blob_key = if pdf_source.include?('/rails/active_storage/blobs/')
                 extract_key_from_rails_path
               elsif pdf_source.include?('/blobs/')
                 extract_key_from_blob_path
               end

    blob_key&.split('?')&.first # Remove query parameters
  end

  def extract_key_from_rails_path
    parts = pdf_source.split('/rails/active_storage/blobs/').last.split('/')
    parts.length > 1 && parts[0] != 'redirect' ? parts[0] : parts[1]
  end

  def extract_key_from_blob_path
    pdf_source.split('/blobs/').last.split('/').first
  end
end