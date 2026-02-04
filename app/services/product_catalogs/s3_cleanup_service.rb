module ProductCatalogs
  class S3CleanupService
    FOLDER = "product-catalog-media"
  
    def initialize(bucket: nil)
      @bucket = bucket || ENV.fetch('S3_BUCKET_NAME', '')
      @s3_client = Aws::S3::Client.new
    end

    def delete_file(s3_key)
      return if s3_key.blank?

      @s3_client.delete_object(
        bucket: @bucket,
        key: s3_key
      )

      Rails.logger.info("Deleted S3 file: #{s3_key}")
      true
    rescue Aws::S3::Errors::NoSuchKey
      Rails.logger.warn("S3 file not found for deletion: #{s3_key}")
      true
    rescue StandardError => e
      Rails.logger.error("Failed to delete S3 file #{s3_key}: #{e.message}")
      false
    end

    def delete_product_folder(account_id, product_id)
      return if account_id.blank? || product_id.blank?

      prefix = "#{account_id}/#{FOLDER}/#{product_id}/"

      # List all objects with the prefix
      objects_to_delete = []
      continuation_token = nil

      loop do
        response = @s3_client.list_objects_v2(
          bucket: @bucket,
          prefix: prefix,
          continuation_token: continuation_token
        )

        objects_to_delete.concat(response.contents.map { |obj| { key: obj.key } })

        break unless response.is_truncated

        continuation_token = response.next_continuation_token
      end

      return true if objects_to_delete.empty?

      # Delete objects in batches of 1000 (S3 limit)
      objects_to_delete.each_slice(1000) do |batch|
        @s3_client.delete_objects(
          bucket: @bucket,
          delete: { objects: batch }
        )
      end

      Rails.logger.info("Deleted S3 folder: #{prefix} (#{objects_to_delete.size} files)")
      true
    rescue StandardError => e
      Rails.logger.error("Failed to delete S3 folder #{prefix}: #{e.message}")
      false
    end
  end
end
