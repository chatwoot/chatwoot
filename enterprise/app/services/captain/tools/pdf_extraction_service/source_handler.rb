module Captain::Tools::PdfExtractionService::SourceHandler
  private

  def determine_source_type
    return :url if pdf_source.is_a?(String) && pdf_source.start_with?('http')
    return :uploaded_file if pdf_source.respond_to?(:tempfile)
    return :active_storage_attachment if pdf_source.is_a?(ActiveStorage::Attached::One)

    :file_path
  end

  def extract_text
    case determine_source_type
    when :url
      extract_from_url
    when :uploaded_file
      extract_from_uploaded_file
    when :active_storage_attachment
      extract_from_attachment
    else
      extract_from_file_path
    end
  end

  def extract_from_url
    return extract_from_active_storage_blob if active_storage_blob_url?

    temp_file = Down.download(
      pdf_source,
      max_size: MAX_PDF_SIZE,
      open_timeout: DOWNLOAD_TIMEOUT,
      read_timeout: DOWNLOAD_TIMEOUT
    )

    begin
      result = extract_from_file(temp_file.path)
    ensure
      temp_file.close
      temp_file.unlink
    end

    result
  end

  def extract_from_uploaded_file
    extract_from_file(pdf_source.tempfile.path)
  end

  def extract_from_file_path
    extract_from_file(pdf_source)
  end

  def extract_from_attachment
    return failure_response(['No file attached']) unless pdf_source.attached?

    pdf_source.open { |file| extract_from_file(file.path) }
  end

  def pdf_source_type
    case pdf_source
    when String
      pdf_source.start_with?('http') ? 'URL' : 'file_path'
    else
      'uploaded_file'
    end
  end
end