class Companies::BusinessEmailDetectorService
  # Paid email services that businesses legitimately use
  # We should not filter these as `free` providers
  PAID_PROVIDERS = %w[fastmail protonmail hey tuta].freeze

  attr_reader :email

  def initialize(email)
    @email = email
  end

  def perform
    return false if email.blank?

    address = ValidEmail2::Address.new(email)
    return false unless address.valid?
    return false if address.disposable_domain?

    provider = EmailProviderInfo.call(email)

    # If no provider found, it's likely a business domain
    return true if provider.nil?

    # If it's a paid provider, treat as business email
    return true if paid_provider?(provider)

    # If it's a known free provider (gmail, yahoo, etc.), not a business email
    false
  end

  private

  def paid_provider?(provider)
    PAID_PROVIDERS.any? { |name| provider.downcase.include?(name) }
  end
end
