require 'aws-sdk-core'
require 'aws-sdk-s3'

class Digitaltolk::UploadToS3
  attr_reader :file_path

  # @param [String] file_path
  def initialize(file_path)
    @file_path = file_path
  end

  # @return [String]
  def perform
    upload_file!
  end

  private

  # @return [String]
  def upload_file!
    obj = bucket.object(file_name)
    obj.upload_file(file_path)
    obj.presigned_url(:get, expires_in: 1.week.to_i)
  end

  # @return [String]
  def bucket_name
    ENV['S3_EXPORT_BUCKET_NAME']
  end

  # @return [Aws::S3::Resource]
  def s3_instance
    if Rails.env.production?
      Aws::S3::Resource.new(region: ENV['DEFAULT_REGION'])
    else
      Aws::S3::Resource.new(
        region: ENV['AWS_REGION'],
        credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
      )
    end
  end

  # @return [Aws::S3::Bucket]
  def bucket
    s3_instance.bucket(bucket_name)
  end

  # @return [String]
  def file_name
    File.basename(file_path)
  end
end