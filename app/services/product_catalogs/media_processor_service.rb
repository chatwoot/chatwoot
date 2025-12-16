class ProductCatalogs::MediaProcessorService
  require 'down'
  require 'open-uri'

  VALID_EXTENSIONS = {
    'IMAGE' => %w[jpg jpeg png gif webp svg],
    'VIDEO' => %w[mp4 avi mov wmv flv webm],
    'AUDIO' => %w[mp3 wav ogg m4a],
    'DOCUMENT' => %w[pdf doc docx xls xlsx txt]
  }.freeze

  def initialize(bulk_request:, user: nil)
    @bulk_request = bulk_request
    @user = user || bulk_request.user
    @errors = []
  end

  def process
    products = @bulk_request.product_catalogs

    products.each_with_index do |product, index|
      process_product_media(product)

      # Update progress (50-100% range for media processing)
      update_progress(index + 1, products.count)
    end

    {
      success: @errors.empty?,
      total_products: products.count,
      errors: @errors
    }
  rescue StandardError => e
    @bulk_request.update!(
      status: 'FAILED',
      error_message: e.message
    )
    { success: false, error: e.message }
  end

  private

  def process_product_media(product)
    # Extract media URLs from metadata if present
    return unless product.metadata.present? && product.metadata['multimedia'].present?

    media_list = product.metadata['multimedia']
    media_list = [media_list] unless media_list.is_a?(Array)

    media_list.each_with_index do |media_url, index|
      process_single_media(product, media_url, index)
    end
  rescue StandardError => e
    @errors << {
      product_id: product.id,
      error: e.message
    }
  end

  def process_single_media(product, media_url, index)
    # media_url can be a string or a hash with url and type
    url = media_url.is_a?(Hash) ? media_url['url'] || media_url[:url] : media_url
    return if url.blank?

    # Validate URL
    uri = URI.parse(url)
    return unless %w[http https].include?(uri.scheme)

    # Extract file extension
    extension = File.extname(uri.path).delete('.').downcase
    file_type = determine_file_type(extension)

    # Validate extension
    validate_extension!(extension, file_type)

    # For now, we'll just store the URL directly without downloading
    # In production, you might want to download and store in S3/Azure
    product.product_media.create!(
      file_type: file_type,
      file_name: File.basename(uri.path),
      file_url: url,
      file_size: nil, # Would be set if downloading
      mime_type: determine_mime_type(extension),
      display_order: index,
      is_primary: index.zero?,
      user_id: @user&.id,
      last_updated_by_id: @user&.id
    )
  rescue StandardError => e
    @errors << {
      product_id: product.id,
      media_url: url,
      error: e.message
    }
  end

  def determine_file_type(extension)
    VALID_EXTENSIONS.each do |type, extensions|
      return type if extensions.include?(extension)
    end
    'OTHER'
  end

  def validate_extension!(extension, file_type)
    return if file_type == 'OTHER'

    valid_exts = VALID_EXTENSIONS[file_type]
    return if valid_exts.include?(extension)

    raise "Invalid file extension '.#{extension}' for type #{file_type}"
  end

  def determine_mime_type(extension)
    mime_types = {
      'jpg' => 'image/jpeg',
      'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'svg' => 'image/svg+xml',
      'mp4' => 'video/mp4',
      'avi' => 'video/x-msvideo',
      'mov' => 'video/quicktime',
      'wmv' => 'video/x-ms-wmv',
      'flv' => 'video/x-flv',
      'webm' => 'video/webm',
      'mp3' => 'audio/mpeg',
      'wav' => 'audio/wav',
      'ogg' => 'audio/ogg',
      'm4a' => 'audio/mp4',
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls' => 'application/vnd.ms-excel',
      'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'txt' => 'text/plain'
    }

    mime_types[extension] || 'application/octet-stream'
  end

  def update_progress(processed_count, total_count)
    # Progress from 50% to 100%
    base_progress = 50.0
    media_progress = (processed_count.to_f / total_count * 50).round(2)
    total_progress = base_progress + media_progress

    @bulk_request.update!(progress: total_progress)
  end
end
