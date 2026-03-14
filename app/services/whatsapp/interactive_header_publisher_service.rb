# frozen_string_literal: true

require 'aws-sdk-s3'

class Whatsapp::InteractiveHeaderPublisherService
  class PublishError < StandardError; end

  def initialize(blob:)
    @blob = blob
  end

  def perform
    validate_blob!

    object_key = [folder_name, generated_filename].join('/').squeeze('/')
    client.put_object(
      bucket: public_bucket,
      key: object_key,
      body: @blob.download,
      content_type: @blob.content_type,
      acl: 'public-read'
    )

    "#{public_bucket_base_url}/#{object_key}"
  rescue Aws::S3::Errors::ServiceError => e
    raise PublishError, "Failed to publish header image: #{e.message}"
  end

  private

  def validate_blob!
    raise PublishError, 'Only image headers are supported' unless @blob.content_type.to_s.start_with?('image/')
  end

  def client
    validate_storage_envs!

    @client ||= Aws::S3::Client.new(
      access_key_id: ENV.fetch('STORAGE_ACCESS_KEY_ID'),
      secret_access_key: ENV.fetch('STORAGE_SECRET_ACCESS_KEY'),
      region: ENV.fetch('STORAGE_REGION', 'us-east-1'),
      endpoint: ENV.fetch('STORAGE_ENDPOINT'),
      force_path_style: ActiveModel::Type::Boolean.new.cast(ENV.fetch('STORAGE_FORCE_PATH_STYLE', 'true'))
    )
  end

  def validate_storage_envs!
    missing_envs = required_storage_envs.select { |env_name| ENV[env_name].blank? }
    return if missing_envs.empty?

    raise PublishError,
          "Missing storage envs for Socialwise bucket publishing: #{missing_envs.join(', ')}"
  end

  def required_storage_envs
    %w[
      STORAGE_ACCESS_KEY_ID
      STORAGE_SECRET_ACCESS_KEY
      STORAGE_ENDPOINT
    ]
  end

  def public_bucket
    ENV.fetch('BUCKET_SOCIALWISE', ENV.fetch('SOCIALWISE_PUBLIC_BUCKET_NAME', 'socialwise'))
  end

  def public_bucket_base_url
    ENV.fetch('SOCIALWISE_PUBLIC_BUCKET_URL', "#{storage_endpoint}/#{public_bucket}")
  end

  def folder_name
    ENV.fetch('SOCIALWISE_PUBLIC_BUCKET_FOLDER', 'whatsapp-cta')
  end

  def storage_endpoint
    ENV.fetch('STORAGE_ENDPOINT').sub(%r{/$}, '')
  end

  def generated_filename
    extension = File.extname(@blob.filename.to_s)
    "#{SecureRandom.uuid}#{extension}"
  end
end
