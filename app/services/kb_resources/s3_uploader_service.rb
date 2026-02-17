module KbResources
  class S3UploaderService
    ALLOWED_CONTENT_TYPES = [
      # Documents
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'text/plain',
      'text/csv',
      'application/json',
      'text/markdown',
      # Images
      'image/png',
      'image/jpeg',
      'image/gif',
      'image/webp',
      'image/svg+xml',
      # Audio
      'audio/mpeg',
      'audio/mp3',
      'audio/wav',
      'audio/wave',
      'audio/x-wav',
      'audio/ogg',
      'audio/mp4',
      'audio/m4a',
      'audio/x-m4a',
      'audio/aac',
      'audio/flac'
    ].freeze

    def initialize(account_id:, bucket: nil)
      @account_id = account_id
      @bucket = bucket || ENV.fetch('S3_BUCKET_NAME', '')
      @s3_client = Aws::S3::Client.new
    end

    def upload(file)
      validate_file!(file)

      s3_key = generate_s3_key(file.original_filename)

      @s3_client.put_object(
        bucket: @bucket,
        key: s3_key,
        body: file.read,
        content_type: file.content_type
      )

      {
        s3_key: s3_key,
        file_name: file.original_filename,
        content_type: file.content_type,
        file_size: file.size
      }
    end

    def delete(s3_key)
      @s3_client.delete_object(bucket: @bucket, key: s3_key)
    rescue StandardError => e
      Rails.logger.error("Failed to delete S3 object #{s3_key}: #{e.message}")
    end

    private

    def validate_file!(file)
      raise ArgumentError, 'No file provided' if file.blank?
      raise ArgumentError, "File too large (max #{KbResource::MAX_FILE_SIZE / 1.megabyte}MB)" if file.size > KbResource::MAX_FILE_SIZE
      raise ArgumentError, 'Invalid file type' unless ALLOWED_CONTENT_TYPES.include?(file.content_type)
    end

    def generate_s3_key(filename)
      safe_filename = File.basename(filename).gsub(/[^\w\-.]/, '_')
      "#{@account_id}/kb-resources/#{SecureRandom.uuid}/#{safe_filename}"
    end
  end
end
