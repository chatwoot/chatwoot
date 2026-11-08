require 'aws-sdk-sesv2'

class Email::SesSuppressionService
  def self.configured?
    ENV['SES_SUPPRESSION_ROLE_ARN'].present?
  end

  def initialize(client: nil)
    @client = client
  end

  def lookup(email)
    destination = client.get_suppressed_destination(email_address: email).suppressed_destination
    { status: destination.reason.downcase.to_sym, since: destination.last_update_time }
  rescue Aws::SESV2::Errors::NotFoundException
    { status: :not_suppressed }
  rescue StandardError => e
    Rails.logger.warn("[SesSuppression] lookup failed: #{e.class} #{e.message}")
    { status: :unavailable }
  end

  def clear!(email)
    client.delete_suppressed_destination(email_address: email)
  end

  private

  # Pinned to the instance role: the default chain would pick up the S3-scoped AWS_ACCESS_KEY_ID.
  def client
    @client ||= Aws::SESV2::Client.new(
      **aws_options,
      credentials: Aws::AssumeRoleCredentials.new(
        client: Aws::STS::Client.new(**aws_options, credentials: Aws::InstanceProfileCredentials.new),
        role_arn: ENV.fetch('SES_SUPPRESSION_ROLE_ARN'),
        role_session_name: 'chatwoot-superadmin-ses'
      )
    )
  end

  def aws_options
    { region: ENV['SES_SUPPRESSION_REGION'].presence || 'us-east-1', http_open_timeout: 3, http_read_timeout: 3 }
  end
end
