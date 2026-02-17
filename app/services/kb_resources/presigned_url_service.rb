module KbResources
  class PresignedUrlService
    DEFAULT_EXPIRATION = ENV.fetch('S3_PRESIGNED_URL_EXPIRATION', 86_400).to_i # 24 hours

    def initialize(bucket: nil)
      @bucket = bucket || ENV.fetch('S3_BUCKET_NAME', '')
      @s3_client = Aws::S3::Client.new
      @signer = Aws::S3::Presigner.new(client: @s3_client)
    end

    def generate_url(s3_key, expires_in: DEFAULT_EXPIRATION)
      return nil if s3_key.blank?

      @signer.presigned_url(
        :get_object,
        bucket: @bucket,
        key: s3_key,
        expires_in: expires_in
      )
    rescue StandardError => e
      Rails.logger.error("Failed to generate presigned URL for #{s3_key}: #{e.message}")
      nil
    end
  end
end
