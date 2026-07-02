module Custom::Integrations::Hook
  def self.prepended(base)
    base.include Custom::Concerns::QuotaGuard
  end
end
