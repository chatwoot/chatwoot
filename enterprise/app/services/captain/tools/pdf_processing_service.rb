class Captain::Tools::PdfProcessingService
  def initialize(document)
    @document = document
    @temp_files = []
  end

  def process
    return unless @document.pdf_document?

    content = extract_text_content
    
    # Follow the same pattern as SimplePageCrawlParserJob
    @document.update!(
      content: content[0..14_999], # Same limit as crawler
      status: :available
    )
    
    content
  rescue StandardError => e
    Rails.logger.error "PDF processing failed for document #{@document.id}: #{e.message}"
    @document.update!(content: "Error processing PDF: #{e.message}", status: :available)
    raise e
  ensure
    cleanup_temp_files
  end

  private

  def extract_text_content
    require 'down'
    
    pdf_file = Down.download(@document.external_link)
    @temp_files << pdf_file
    
    output_dir = Dir.mktmpdir
    @temp_files << output_dir
    
    # Convert PDF to images
    system("pdftoimage", "-png", "-r", "150", pdf_file.path, "#{output_dir}/page")
    
    image_files = Dir.glob("#{output_dir}/page-*.png").sort
    return fallback_content if image_files.empty?
    
    # Batch pages for efficient processing
    batcher = Captain::Tools::PdfPageBatcherService.new(@temp_files)
    batched_images = batcher.batch_pages(image_files)
    
    # Extract text using Google Vision
    vision_extractor = Captain::Tools::VisionTextExtractorService.new
    extracted_text = vision_extractor.extract_text_from_multiple_images(batched_images)
    
    extracted_text.present? ? extracted_text : fallback_content
  end

  def fallback_content
    "PDF Document: #{@document.name || 'Untitled'}\nSource: #{@document.external_link}"
  end

  def cleanup_temp_files
    @temp_files.each do |file_or_dir|
      case file_or_dir
      when String # directory path
        FileUtils.rm_rf(file_or_dir)
      when Tempfile
        file_or_dir.close
        file_or_dir.unlink
      else # Down::ChunkedIO or similar
        file_or_dir.close if file_or_dir.respond_to?(:close)
        file_or_dir.unlink if file_or_dir.respond_to?(:unlink)
      end
    rescue StandardError => e
      Rails.logger.warn "Failed to cleanup temp file: #{e.message}"
    end
  end
end