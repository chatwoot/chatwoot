require 'aws-sdk-s3'

Aws.config.update({
  region: ENV.fetch('AWS_REGION', 'us-east-1'),
  credentials: Aws::Credentials.new(
    ENV.fetch('AWS_ACCESS_KEY_ID', ''),
    ENV.fetch('AWS_SECRET_ACCESS_KEY', '')
  )
})
