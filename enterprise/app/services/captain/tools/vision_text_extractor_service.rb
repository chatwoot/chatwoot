class Captain::Tools::VisionTextExtractorService
  class TextExtractionError < StandardError; end

  def initialize
    @use_vision = vision_available?
    @vision = Google::Cloud::Vision.image_annotator if @use_vision
  end

  def extract_text_from_image(image_path)
    if @use_vision
      extract_with_vision(image_path)
    else
      extract_with_tesseract(image_path)
    end
  end

  def extract_text_from_multiple_images(image_paths)
    Rails.logger.info "Using #{@use_vision ? 'Google Vision' : 'Tesseract'} for text extraction"
    
    extracted_texts = []
    
    image_paths.each_with_index do |image_path, index|
      Rails.logger.info "Extracting text from image #{index + 1}/#{image_paths.length}"
      
      text = extract_text_from_image(image_path)
      extracted_texts << text if text.present?
    end
    
    extracted_texts.join("\n\n")
  end

  private

  def vision_available?
    require 'google/cloud/vision'
    Google::Cloud::Vision.image_annotator
    true
  rescue StandardError => e
    Rails.logger.info "Google Vision not available, falling back to Tesseract: #{e.message}"
    false
  end

  def extract_with_vision(image_path)
    image = Google::Cloud::Vision::Image.new(image_path)
    response = @vision.text_detection(image: image)
    
    if response.error
      raise TextExtractionError, "Vision API error: #{response.error.message}"
    end
    
    text_annotation = response.full_text_annotation
    return "" unless text_annotation
    
    text_annotation.text
  rescue Google::Cloud::Error => e
    Rails.logger.error "Google Vision API error: #{e.message}"
    raise TextExtractionError, "Failed to extract text: #{e.message}"
  end

  def extract_with_tesseract(image_path)
    require 'rtesseract'
    
    RTesseract.new(image_path).to_s.strip
  rescue StandardError => e
    Rails.logger.error "Tesseract extraction error: #{e.message}"
    raise TextExtractionError, "Failed to extract text with Tesseract: #{e.message}"
  end
end