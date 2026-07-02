module Custom::Team
  def self.prepended(base)
    base.include Custom::Concerns::QuotaGuard
  end
end
