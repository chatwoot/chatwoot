module Custom::Api::V1::Accounts::AgentBotsController
  def self.prepended(base)
    base.include Custom::Concerns::QuotaEnforcement
    base.include Custom::Concerns::PlatformActor
    base.before_action :check_agent_bots_quota, only: [:create]
  end

  private

  def check_agent_bots_quota
    # The system AI AgentBot is platform-managed infrastructure — exempt from
    # tenant entitlements (never counted, never blocked). The exemption is granted
    # ONLY when the acting identity is itself platform-managed (the control plane's
    # service user), never on a tenant-supplied flag, so a tenant admin cannot
    # self-exempt. See docs/fork/adr/0005.
    return if platform_managed_agent_bot?

    check_quota(:agent_bots)
  end

  def platform_managed_agent_bot?
    platform_actor? && ActiveModel::Type::Boolean.new.cast(params[:platform_managed])
  end

  # Strip `platform_managed` from tenant-controllable input: only a platform actor
  # may set it (on create OR update). Anyone else has the key dropped, so the
  # column keeps its `false` default and the record counts against the tenant.
  def permitted_params
    permitted = params.permit(:name, :description, :outgoing_url, :avatar, :avatar_url, :bot_type, :platform_managed, bot_config: {})
    permitted.delete(:platform_managed) unless platform_actor?
    permitted
  end
end
