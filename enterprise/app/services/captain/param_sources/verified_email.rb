# The email the customer verified with a one-time code in this conversation
class Captain::ParamSources::VerifiedEmail
  NAME = 'verified.email'.freeze
  UNVERIFIED = 'This tool needs a verified email, and this customer has not verified an email yet. ' \
               'Verify their email with a one-time code first, then call this tool again. ' \
               'If that is not possible, ask whether they want to talk to a support agent.'.freeze

  def self.parse(name)
    new if name == NAME
  end

  def validate(_account); end

  def resolve(conversation)
    email = conversation && Captain::EmailVerification.new(conversation).verified_email
    email || raise(Captain::ParamSources::Unavailable, UNVERIFIED)
  end
end
