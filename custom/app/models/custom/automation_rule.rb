module Custom::AutomationRule
  def self.prepended(base)
    base.include Custom::Concerns::QuotaGuard
  end
end
