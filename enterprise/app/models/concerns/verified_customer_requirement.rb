# Whether a Captain tool runs only for a customer who verified an email with a one-time code, so Captain offers
# email verification first. Custom tools and MCP tools share this rule.
#
# The admin can turn it on with the requires_email_verification setting. A tool with a parameter that takes the
# verified email cannot be filled without one, so it needs no setting. Each tool says whether it has such a
# parameter with takes_verified_email?.
module Concerns::VerifiedCustomerRequirement
  extend ActiveSupport::Concern

  def requires_verified_customer?
    settings['requires_email_verification'] == true || takes_verified_email?
  end
end
