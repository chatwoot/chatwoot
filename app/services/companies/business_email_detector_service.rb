class Companies::BusinessEmailDetectorService
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

    provider.nil?
  end
end
