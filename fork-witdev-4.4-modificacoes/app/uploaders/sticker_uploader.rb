# StickerUploader handles image processing for custom stickers
# Converts images to WebP format with 512x512 dimensions and validates file size
# Migrated to ruby-vips for better performance and WebP support
require 'vips'
require 'tempfile'

class StickerUploader
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  attribute :file
  attribute :pack_name, :string
  attribute :tags, default: []

  validates :file, presence: true
  validates :pack_name, presence: true, length: { minimum: 1, maximum: 50 }
  validate :validate_image_file
  validate :validate_file_size

  MAX_FILE_SIZE = 5.megabytes # Input file size limit
  MAX_OUTPUT_SIZE = 500.kilobytes # WhatsApp sticker size limit (500KB - back to WhatsApp standard)
  STICKER_DIMENSIONS = 512

  def process_and_validate
    return false unless valid?

    begin
      @processed_file = process_image
      validate_processed_file
      valid?
    rescue StandardError => e
      errors.add(:file, "Processing failed: #{e.message}")
      false
    end
  end

  def processed_file
    @processed_file
  end

  def processed_filename
    "sticker_#{SecureRandom.hex(8)}.webp"
  end

  private

  def validate_image_file
    return unless file

    unless file.respond_to?(:content_type) && file.content_type&.start_with?('image/')
      errors.add(:file, 'must be an image file')
      return
    end

    # Check if it's a supported image format
    supported_formats = %w[image/jpeg image/jpg image/png image/gif image/webp image/bmp image/tiff]
    unless supported_formats.include?(file.content_type.downcase)
      errors.add(:file, 'format not supported. Please use JPEG, PNG, GIF, WebP, BMP, or TIFF')
    end
  end

  def validate_file_size
    return unless file&.respond_to?(:size)

    if file.size > MAX_FILE_SIZE
      errors.add(:file, "is too large. Maximum size is #{MAX_FILE_SIZE / 1.megabyte}MB")
    end
  end

  def process_image
    # Detect if we need special handling for animation/transparency
    needs_optimizer = needs_special_processing?
    
    Rails.logger.info "[STICKER_UPLOADER] Processing sticker: content_type=#{file.content_type}, needs_optimizer=#{needs_optimizer}"
    
    if needs_optimizer
      Rails.logger.info "[STICKER_UPLOADER] 🎬 Using StickerImageOptimizerService for animation/transparency preservation"
      process_with_optimizer
    else
      Rails.logger.info "[STICKER_UPLOADER] ⚡ Using fast Vips processing for static image"
      process_with_vips
    end
  end

  def needs_special_processing?
    return false unless file.respond_to?(:content_type)
    
    content_type = file.content_type&.downcase
    
    # Always use optimizer for GIFs (likely animated)
    return true if content_type == 'image/gif'
    
    # For WebP, check if it's actually animated using ruby-vips
    if content_type == 'image/webp'
      begin
        # Quick check for animation without full processing
        file.rewind if file.respond_to?(:rewind)
        file_content = file.read
        file.rewind if file.respond_to?(:rewind)
        
        temp_image = Vips::Image.new_from_buffer(file_content, "", access: :sequential)
        frame_count = temp_image.get('n-pages') rescue 1
        
        if frame_count > 1
          Rails.logger.info "[STICKER_UPLOADER] 🎬 WebP animated detected (#{frame_count} frames)"
          return true
        else
          Rails.logger.info "[STICKER_UPLOADER] �️ WebP static detected"
        end
      rescue => e
        Rails.logger.warn "[STICKER_UPLOADER] ⚠️ Could not analyze WebP: #{e.message}, using optimizer as fallback"
        return true # Better safe than sorry
      end
    end
    
    # For PNG, check if it has transparency using ruby-vips
    if content_type == 'image/png'
      begin
        file.rewind if file.respond_to?(:rewind)
        file_content = file.read
        file.rewind if file.respond_to?(:rewind)
        
        temp_image = Vips::Image.new_from_buffer(file_content, "", access: :sequential)
        has_alpha = temp_image.has_alpha?
        
        if has_alpha
          Rails.logger.info "[STICKER_UPLOADER] 🎨 PNG with transparency detected"
          return true
        else
          Rails.logger.info "[STICKER_UPLOADER] 🖼️ PNG without transparency detected"
        end
      rescue => e
        Rails.logger.warn "[STICKER_UPLOADER] ⚠️ Could not analyze PNG: #{e.message}, preserving transparency as fallback"
        return true # Better safe than sorry
      end
    end
    
    # JPEG and other formats can use fast processing
    Rails.logger.info "[STICKER_UPLOADER] ⚡ Standard format detected (#{content_type}), using fast processing"
    false
  end

  def process_with_optimizer
    start_time = Time.current
    
    # Create temporary input file for the optimizer with correct extension
    # Use content_type to determine extension to preserve animation in WebP files
    correct_extension = get_extension_from_content_type(file.content_type) || File.extname(file.original_filename || '.tmp')
    temp_input = Tempfile.new(['sticker_input', correct_extension])
    temp_input.binmode
    
    # Write file content to temp file
    file.rewind if file.respond_to?(:rewind)
    temp_input.write(file.read)
    temp_input.close
    
    Rails.logger.info "[STICKER_UPLOADER] 📝 Created temp input: #{temp_input.path}"
    Rails.logger.info "[STICKER_UPLOADER] 🔧 Content-Type: #{file.content_type}, Extension: #{correct_extension}"
    
    # Check original frames before processing
    begin
      # Use ruby-vips to detect animation instead of MiniMagick
      temp_image = Vips::Image.new_from_file(temp_input.path, access: :sequential)
      original_frames = temp_image.get('n-pages') rescue 1
      Rails.logger.info "🎬 [FRAMES] UPLOADER Input: #{original_frames} frames"
    rescue => e
      Rails.logger.warn "Could not detect original frames in uploader: #{e.message}"
      original_frames = "unknown"
    end
    
    # Use the optimizer service
    optimizer = StickerImageOptimizerService.new(
      file: File.open(temp_input.path, 'rb'),
      account_id: nil # We don't have account context in uploader
    )
    
    result = optimizer.process
    processing_time = (Time.current - start_time) * 1000
    
    if result[:success]
      Rails.logger.info "[STICKER_UPLOADER] ✅ Optimizer success: #{result[:final_size]} bytes, #{processing_time.round(2)}ms"
      Rails.logger.info "[STICKER_UPLOADER] 📊 Animation: #{result[:is_animated]}, Transparency: #{result[:has_transparency]}"
      Rails.logger.info "[STICKER_UPLOADER] 🗜️ Compression: #{result[:compression_ratio]}%"
      
      # Check frames after processing using ruby-vips
      begin
        if result[:processed_file].respond_to?(:tempfile)
          processed_image = Vips::Image.new_from_file(result[:processed_file].tempfile.path, access: :sequential)
        elsif result[:processed_file].respond_to?(:path)
          processed_image = Vips::Image.new_from_file(result[:processed_file].path, access: :sequential)
        end
        
        if processed_image
          processed_frames = processed_image.get('n-pages') rescue 1
          Rails.logger.info "🎬 [FRAMES] UPLOADER Output: #{processed_frames} frames (original: #{original_frames})"
        end
      rescue => e
        Rails.logger.warn "Could not detect processed frames in uploader: #{e.message}"
      end
      
      result[:processed_file]
    else
      Rails.logger.error "[STICKER_UPLOADER] ❌ Optimizer failed: #{result[:error]}, falling back to Vips"
      process_with_vips
    end
  ensure
    temp_input&.unlink
  end

  def process_with_vips
    start_time = Time.current
    
    Rails.logger.info "[STICKER_UPLOADER] ⚡ Using ruby-vips direct processing"
    
    # Read file content into buffer
    file.rewind if file.respond_to?(:rewind)
    file_content = file.read
    file.rewind if file.respond_to?(:rewind)
    
    # Load image from buffer using ruby-vips directly
    source_image = Vips::Image.new_from_buffer(file_content, "", access: :sequential)
    
    # Resize to sticker dimensions (512x512) with center crop
    processed_image = source_image.thumbnail_image(STICKER_DIMENSIONS, height: STICKER_DIMENSIONS, crop: :centre)
    
    # Convert to WebP with good quality settings
    webp_buffer = processed_image.webpsave_buffer(Q: 85, effort: 6)

    processing_time = (Time.current - start_time) * 1000
    Rails.logger.info "[STICKER_UPLOADER] ⚡ ruby-vips processing completed in #{processing_time.round(2)}ms"

    # Create a temporary file with the processed image
    temp_file = Tempfile.new(['processed_sticker', '.webp'])
    temp_file.binmode
    temp_file.write(webp_buffer)
    temp_file.rewind
    
    file_size = temp_file.size
    Rails.logger.info "[STICKER_UPLOADER] 📦 ruby-vips output: #{file_size} bytes"
    
    temp_file
  rescue Vips::Error => e
    Rails.logger.error "[STICKER_UPLOADER] ❌ ruby-vips processing failed: #{e.message}"
    
    # Fallback: try with file path instead of buffer
    temp_input = Tempfile.new(['sticker_fallback', get_extension_from_content_type(file.content_type) || '.tmp'])
    begin
      temp_input.binmode
      temp_input.write(file_content)
      temp_input.close
      
      source_image = Vips::Image.new_from_file(temp_input.path, access: :sequential)
      processed_image = source_image.thumbnail_image(STICKER_DIMENSIONS, height: STICKER_DIMENSIONS, crop: :centre)
      webp_buffer = processed_image.webpsave_buffer(Q: 85, effort: 6)
      
      temp_file = Tempfile.new(['processed_sticker_fallback', '.webp'])
      temp_file.binmode
      temp_file.write(webp_buffer)
      temp_file.rewind
      
      Rails.logger.info "[STICKER_UPLOADER] ✅ Fallback processing successful"
      temp_file
    ensure
      temp_input.unlink if temp_input
    end
  end

  def validate_processed_file
    return unless @processed_file

    file_size = @processed_file.size
    if file_size > MAX_OUTPUT_SIZE
      # Try with lower quality if file is too large
      @processed_file = reprocess_with_lower_quality
      file_size = @processed_file.size

      if file_size > MAX_OUTPUT_SIZE
        errors.add(:file, "processed file is too large (#{file_size / 1.kilobyte}KB). WhatsApp stickers must be under #{MAX_OUTPUT_SIZE / 1.kilobyte}KB")
      end
    end
  end

  def reprocess_with_lower_quality
    Rails.logger.info "[STICKER_UPLOADER] 🔄 Reprocessing with lower quality (Q=60)"
    
    # Read file content into buffer
    file.rewind if file.respond_to?(:rewind)
    file_content = file.read
    file.rewind if file.respond_to?(:rewind)
    
    begin
      # Load and process with lower quality using ruby-vips
      source_image = Vips::Image.new_from_buffer(file_content, "", access: :sequential)
      processed_image = source_image.thumbnail_image(STICKER_DIMENSIONS, height: STICKER_DIMENSIONS, crop: :centre)
      
      # Lower quality for smaller file size
      webp_buffer = processed_image.webpsave_buffer(Q: 60, effort: 6)
      
      temp_file = Tempfile.new(['processed_sticker_low_quality', '.webp'])
      temp_file.binmode
      temp_file.write(webp_buffer)
      temp_file.rewind
      
      Rails.logger.info "[STICKER_UPLOADER] 📦 Low quality output: #{temp_file.size} bytes"
      temp_file
      
    rescue Vips::Error => e
      Rails.logger.error "[STICKER_UPLOADER] ❌ Low quality reprocessing failed: #{e.message}"
      
      # Fallback with file path
      temp_input = Tempfile.new(['sticker_lowq_fallback', get_extension_from_content_type(file.content_type) || '.tmp'])
      begin
        temp_input.binmode
        temp_input.write(file_content)
        temp_input.close
        
        source_image = Vips::Image.new_from_file(temp_input.path, access: :sequential)
        processed_image = source_image.thumbnail_image(STICKER_DIMENSIONS, height: STICKER_DIMENSIONS, crop: :centre)
        webp_buffer = processed_image.webpsave_buffer(Q: 60, effort: 6)
        
        temp_file = Tempfile.new(['processed_sticker_lowq_fallback', '.webp'])
        temp_file.binmode
        temp_file.write(webp_buffer)
        temp_file.rewind
        temp_file
      ensure
        temp_input.unlink if temp_input
      end
    end
  end

  def get_extension_from_content_type(content_type)
    return nil unless content_type
    
    case content_type.downcase
    when 'image/webp'
      '.webp'
    when 'image/gif'
      '.gif'
    when 'image/png'
      '.png'
    when 'image/jpeg', 'image/jpg'
      '.jpg'
    when 'image/bmp'
      '.bmp'
    when 'image/tiff'
      '.tiff'
    else
      nil
    end
  end
end