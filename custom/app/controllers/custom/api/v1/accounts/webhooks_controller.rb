module Custom::Api::V1::Accounts::WebhooksController
  def self.prepended(base)
    base.include Custom::Concerns::QuotaEnforcement
    base.include Custom::Concerns::PlatformActor
    base.before_action :check_webhooks_quota, only: [:create]
  end

  private

  def check_webhooks_quota
    # The orchestrator-ingest webhook is platform-managed infrastructure — exempt
    # from tenant entitlements (never counted, never blocked). The exemption is
    # granted ONLY when the acting identity is itself platform-managed (the control
    # plane's service user), never on a tenant-supplied flag, so a tenant admin
    # cannot self-exempt. See docs/fork/adr/0005.
    return if platform_managed_webhook?

    check_quota(:webhooks)
  end

  def platform_managed_webhook?
    platform_actor? && ActiveModel::Type::Boolean.new.cast(params.dig(:webhook, :platform_managed))
  end

  # Strip `platform_managed` from tenant-controllable input: only a platform actor
  # may set it (on create OR update). Anyone else has the key dropped, so the
  # column keeps its `false` default and the record counts against the tenant.
  def webhook_params
    permitted = params.require(:webhook).permit(:inbox_id, :name, :url, :platform_managed, subscriptions: [])
    permitted.delete(:platform_managed) unless platform_actor?
    permitted
  end
end
