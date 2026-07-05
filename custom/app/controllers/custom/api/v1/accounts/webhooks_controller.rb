module Custom::Api::V1::Accounts::WebhooksController
  def self.prepended(base)
    base.include Custom::Concerns::QuotaEnforcement
    base.before_action :check_webhooks_quota, only: [:create]
  end

  private

  def check_webhooks_quota
    # The orchestrator-ingest webhook is platform-managed infrastructure — exempt
    # from tenant entitlements (never counted, never blocked). Webhook create is
    # administrator-only (WebhookPolicy#create?), and the only administrator in
    # this SaaS is the platform's service user, so the flag is not tenant-settable
    # in practice. See docs/fork/adr/0002.
    return if platform_managed_param?

    check_quota(:webhooks)
  end

  def platform_managed_param?
    ActiveModel::Type::Boolean.new.cast(params.dig(:webhook, :platform_managed))
  end

  def webhook_params
    params.require(:webhook).permit(:inbox_id, :name, :url, :platform_managed, subscriptions: [])
  end
end
