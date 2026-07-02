module Custom::Api::V1::Accounts::AutomationRulesController
  def self.prepended(base)
    base.include Custom::Concerns::QuotaEnforcement
    base.before_action :check_automation_rules_quota, only: [:create, :clone]
  end

  private

  def check_automation_rules_quota
    check_quota(:automation_rules)
  end
end
