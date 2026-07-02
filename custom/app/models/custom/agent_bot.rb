module Custom::AgentBot
  def self.prepended(base)
    base.include Custom::Concerns::QuotaGuard
  end
end
