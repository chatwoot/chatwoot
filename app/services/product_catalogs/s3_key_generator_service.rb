module ProductCatalogs
  class S3KeyGeneratorService
    FOLDER = "product-catalog-media"

    FILE_TYPE_FOLDERS = {
      'IMAGE' => 'images',
      'VIDEO' => 'videos',
      'DOCUMENT' => 'docs',
      'AUDIO' => 'audio'
    }.freeze

    def initialize(account_id:, product_id:, file_type:, filename:)
      @account_id = account_id
      @product_id = product_id
      @file_type = file_type.to_s.upcase
      @filename = sanitize_filename(filename)
    end

    def generate
      folder = FILE_TYPE_FOLDERS[@file_type]
      raise ArgumentError, "Unsupported file type: #{@file_type}" if folder.nil?

      "#{@account_id}/#{FOLDER}/#{@product_id}/#{folder}/#{@filename}"
    end

    private

    def sanitize_filename(filename)
      # Remove or replace invalid characters for S3 keys
      sanitized = filename.to_s.strip
      sanitized = sanitized.gsub(/[^\w\-.]/, '_')
      sanitized = "file_#{Time.current.to_i}" if sanitized.blank?
      sanitized
    end
  end
end
