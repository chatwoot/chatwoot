# A Captain tool whose parameter can take the email a customer verified with a one-time code.
# Each tool stores its parameters differently, so it lists its sources by parameter name in sources_by_param.
module Concerns::VerifiedEmailSourceable
  extend ActiveSupport::Concern

  VERIFIED_EMAIL_SOURCE = 'verified.email'.freeze

  # The tool only runs for a customer who verified an email with a one-time code.
  # A tool with a parameter that takes the verified email cannot run without one, so it needs no setting.
  def requires_email_verification?
    settings['requires_email_verification'] == true || sources_by_param.value?(VERIFIED_EMAIL_SOURCE)
  end

  # The name of the parameter Chatwoot fills with the verified email, if the tool has one
  def verified_email_param
    sources_by_param.key(VERIFIED_EMAIL_SOURCE)
  end
end
