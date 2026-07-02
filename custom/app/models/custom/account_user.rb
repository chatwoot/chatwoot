# Enforces the agents quota at the AccountUser level so every path that adds
# a user to an account is covered — including the Platform API
# (platform/api/v1/account_users#create), which bypasses AgentBuilder.
module Custom::AccountUser
  def self.prepended(base)
    base.include Custom::Concerns::QuotaGuard
  end
end
