require 'aws-sdk-core'
require 'aws-sdk-s3'

if Rails.env.development?
  Aws.config.update({
    region: ENV['AWS_REGION'],
    credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
  })
end
