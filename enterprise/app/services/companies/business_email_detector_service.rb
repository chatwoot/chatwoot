class Companies::BusinessEmailDetectorService
  # FIXME: It should be possible to do this another way,
  # check the ticket
  FREE_DOMAINS = %w[
    gmail.com yahoo.com hotmail.com outlook.com
    aol.com icloud.com mail.com protonmail.com
    live.com msn.com yandex.com zoho.com
    gmx.com inbox.com
    uol.com.br bol.com.br terra.com.br ig.com.br
    sapo.pt iol.pt
    terra.es hotmail.es yahoo.es
  ].freeze

  attr_reader :email

  def initialize(email)
    @email = email
  end

  def perform
    return false if email.blank?

    address = ValidEmail2::Address.new(email)
    return false unless address.valid?
    return false if address.disposable_domain?

    domain = extract_domain(email)
    FREE_DOMAINS.exclude?(domain)
  end

  private

  def extract_domain(email)
    email.split('@').last&.downcase
  end
end
