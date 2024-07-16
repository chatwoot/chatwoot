require 'aws-sdk-core'
require 'aws-sdk-s3'

if Rails.env.production?
  Aws.config.update({
    region: ENV['DEFAULT_REGION'],
    credentials: Aws::InstanceProfileCredentials.new
  })
else
  Aws.config.update({
    region: ENV['AWS_REGION'],
    credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
  })
end
