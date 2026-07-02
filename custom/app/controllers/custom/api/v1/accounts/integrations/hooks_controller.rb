module Custom::Api::V1::Accounts::Integrations::HooksController
  def self.prepended(base)
    base.include Custom::Concerns::QuotaEnforcement
    base.before_action :check_integrations_quota, only: [:create]
  end

  private

  def check_integrations_quota
    check_quota(:integrations)
  end
end
