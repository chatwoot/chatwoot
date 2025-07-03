module Captain::Tools::PdfExtractionService::TextProcessor
  private

  def extract_from_file(file_path)
    text_content = []

    PDF::Reader.open(file_path) do |reader|
      reader.pages.each_with_index do |page, index|
        page_content = extract_page_content(page, index)
        text_content << page_content if page_content
      end
    end

    text_content
  end

  def extract_page_content(page, index)
    page_text = page.text
    return nil if page_text.blank?

    cleaned_text = clean_text(page_text)
    return nil if cleaned_text.blank?

    { page_number: index + 1, content: cleaned_text }
  rescue StandardError => e
    Rails.logger.warn "Failed to extract text from page #{index + 1}: #{e.message}"
    nil
  end

  def clean_text(text)
    # Remove form feeds and normalize whitespace
    cleaned = text.tr("\f", "\n")
                  .gsub("\r\n", "\n")
                  .tr("\r", "\n")
                  .gsub(/\s+/, ' ')
                  .gsub(/\n\s*\n\s*\n+/, "\n\n")
                  .strip

    # Remove common PDF artifacts
    cleaned = cleaned.gsub(/^\d+\s*$/, '') # Remove standalone page numbers
                     .gsub(/^[\s\-_=]+$/, '') # Remove separator lines
                     .strip

    cleaned.presence
  end
end