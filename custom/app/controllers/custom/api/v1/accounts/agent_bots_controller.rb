module Custom::Api::V1::Accounts::AgentBotsController
  def self.prepended(base)
    base.include Custom::Concerns::QuotaEnforcement
    base.before_action :check_agent_bots_quota, only: [:create]
  end

  private

  def check_agent_bots_quota
    # The system AI AgentBot is platform-managed infrastructure — exempt from
    # tenant entitlements (never counted, never blocked). AgentBot create is
    # administrator-only (AgentBotPolicy#create?); the only administrator here is
    # the platform's service user, so the flag is not tenant-settable in practice.
    # See docs/fork/adr/0002.
    return if ActiveModel::Type::Boolean.new.cast(params[:platform_managed])

    check_quota(:agent_bots)
  end

  def permitted_params
    params.permit(:name, :description, :outgoing_url, :avatar, :avatar_url, :bot_type, :platform_managed, bot_config: {})
  end
end
