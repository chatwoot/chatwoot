# Answers "may this member use feature X?" for one account. Every role-based access decision a
# gated feature makes goes through here, so a downstream build can refine it by prepending a
# `<Extension>::FeatureAccess` module (see `prepend_mod_with` below) without touching the callers.
#
# This class is the default: administrators may use everything, agents get the capability's
# `agent_default`, and someone without a membership in the account gets nothing.
class FeatureAccess
  CAPABILITIES = {
    'internal_chat.access' => { agent_default: true }
  }.freeze

  attr_reader :account

  def initialize(account)
    @account = account
  end

  def capabilities
    CAPABILITIES
  end

  def allows?(account_user, capability)
    config = capabilities.fetch(capability)
    return false if account_user.nil? || account_user.account_id != account.id
    return true if account_user.administrator?

    agent_allows?(account_user, capability, config)
  end

  # The account's users holding the capability, as a relation, for audiences and candidate lists.
  def users_with(capability)
    return account.users if capabilities.fetch(capability)[:agent_default]

    account.users.where(account_users: { role: AccountUser.roles[:administrator] })
  end

  def granted(account_user)
    capabilities.keys.select { |capability| allows?(account_user, capability) }
  end

  private

  def agent_allows?(_account_user, _capability, config)
    config[:agent_default]
  end
end

FeatureAccess.prepend_mod_with('FeatureAccess')
