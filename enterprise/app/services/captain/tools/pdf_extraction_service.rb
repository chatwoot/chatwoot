require 'pdf-reader'

class Captain::Tools::PdfExtractionService
  include ActiveModel::Validations

  attr_reader :pdf_source, :errors

  def initialize(pdf_source)
    @pdf_source = pdf_source
    @errors = []
  end

  def perform
    return { success: false, errors: ['Invalid PDF source'] } if pdf_source.blank?

    begin
      validate_pdf_source
      content = extract_text
      chunked_content = chunk_content(content)
      { success: true, content: chunked_content }
    rescue PDF::Reader::MalformedPDFError => e
      Rails.logger.error "Malformed PDF: #{e.message}"
      { success: false, errors: ['Invalid PDF format'] }
    rescue StandardError => e
      Rails.logger.error "PDF extraction error: #{e.message}"
      { success: false, errors: [e.message] }
    end
  end

  def extract_text
    if pdf_source.is_a?(String) && pdf_source.start_with?('http')
      extract_from_url
    elsif pdf_source.respond_to?(:tempfile)
      extract_from_uploaded_file
    else
      extract_from_file_path
    end
  end

  private

  def validate_pdf_source
    if pdf_source.is_a?(String) && pdf_source.start_with?('http')
      validate_url
    elsif pdf_source.respond_to?(:tempfile)
      validate_uploaded_file
    else
      validate_file_path
    end
  end

  def validate_url
    uri = URI.parse(pdf_source)
    raise StandardError, 'Invalid URL' unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  end

  def validate_uploaded_file
    raise StandardError, 'File too large' if pdf_source.size > 10.megabytes
    raise StandardError, 'Invalid file type' unless pdf_source.content_type == 'application/pdf'
  end

  def validate_file_path
    raise StandardError, 'File does not exist' unless File.exist?(pdf_source)
    raise StandardError, 'File too large' if File.size(pdf_source) > 10.megabytes
  end

  def extract_from_url
    temp_file = Down.download(pdf_source)
    result = extract_from_file(temp_file.path)
    temp_file.close
    temp_file.unlink
    result
  end

  def extract_from_uploaded_file
    extract_from_file(pdf_source.tempfile.path)
  end

  def extract_from_file_path
    extract_from_file(pdf_source)
  end

  def extract_from_file(file_path)
    text_content = []
    
    PDF::Reader.open(file_path) do |reader|
      reader.pages.each_with_index do |page, index|
        begin
          page_text = page.text
          next if page_text.blank?
          
          cleaned_text = clean_text(page_text)
          text_content << {
            page_number: index + 1,
            content: cleaned_text
          } if cleaned_text.present?
        rescue StandardError => e
          Rails.logger.warn "Failed to extract text from page #{index + 1}: #{e.message}"
          next
        end
      end
    end

    text_content
  end

  def clean_text(text)
    # Remove form feeds and normalize whitespace
    cleaned = text.gsub(/\f/, "\n")
                  .gsub(/\r\n/, "\n")
                  .gsub(/\r/, "\n")
                  .gsub(/\s+/, ' ')
                  .gsub(/\n\s*\n\s*\n+/, "\n\n")
                  .strip

    # Remove common PDF artifacts
    cleaned = cleaned.gsub(/^\d+\s*$/, '') # Remove standalone page numbers
                    .gsub(/^[\s\-_=]+$/, '') # Remove separator lines
                    .strip

    cleaned.present? ? cleaned : nil
  end

  def chunk_content(page_contents, max_chunk_size: 2000)
    return [] if page_contents.blank?

    chunks = []
    
    page_contents.each do |page_data|
      content = page_data[:content]
      page_number = page_data[:page_number]
      
      # If content is small enough, keep as single chunk
      if content.length <= max_chunk_size
        chunks << {
          content: content,
          page_number: page_number,
          chunk_index: 1,
          total_chunks: 1
        }
      else
        # Split large content into smaller chunks
        page_chunks = split_content_into_chunks(content, max_chunk_size)
        page_chunks.each_with_index do |chunk_content, index|
          chunks << {
            content: chunk_content,
            page_number: page_number,
            chunk_index: index + 1,
            total_chunks: page_chunks.length
          }
        end
      end
    end

    chunks
  end

  def split_content_into_chunks(content, max_size)
    # Split by paragraphs first
    paragraphs = content.split(/\n\s*\n/)
    chunks = []
    current_chunk = ""

    paragraphs.each do |paragraph|
      # If adding this paragraph would exceed the limit
      if (current_chunk + "\n\n" + paragraph).length > max_size
        # Save current chunk if it has content
        chunks << current_chunk.strip if current_chunk.present?
        
        # If single paragraph is too large, split by sentences
        if paragraph.length > max_size
          sentences = paragraph.split(/(?<=[.!?])\s+/)
          current_chunk = ""
          
          sentences.each do |sentence|
            if (current_chunk + " " + sentence).length > max_size
              chunks << current_chunk.strip if current_chunk.present?
              current_chunk = sentence
            else
              current_chunk += (current_chunk.present? ? " " : "") + sentence
            end
          end
        else
          current_chunk = paragraph
        end
      else
        current_chunk += (current_chunk.present? ? "\n\n" : "") + paragraph
      end
    end

    # Add the last chunk
    chunks << current_chunk.strip if current_chunk.present?
    chunks
  end
end