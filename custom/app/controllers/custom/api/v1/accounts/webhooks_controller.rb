module Custom::Api::V1::Accounts::WebhooksController
  def self.prepended(base)
    base.include Custom::Concerns::QuotaEnforcement
    base.before_action :check_webhooks_quota, only: [:create]
  end

  private

  def check_webhooks_quota
    check_quota(:webhooks)
  end
end
