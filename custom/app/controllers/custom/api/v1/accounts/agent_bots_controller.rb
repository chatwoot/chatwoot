module Custom::Api::V1::Accounts::AgentBotsController
  def self.prepended(base)
    base.include Custom::Concerns::QuotaEnforcement
    base.before_action :check_agent_bots_quota, only: [:create]
  end

  private

  def check_agent_bots_quota
    check_quota(:agent_bots)
  end
end
