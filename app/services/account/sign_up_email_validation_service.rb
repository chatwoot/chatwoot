# frozen_string_literal: true

class Account::SignUpEmailValidationService
  attr_reader :email

  def initialize(email)
    @email = email
  end

  def perform
    address = ValidEmail2::Address.new(email)

    raise_invalid(valid: false, disposable: nil) unless address.valid?
    raise_invalid(domain_blocked: true) if domain_blocked?
    raise_invalid(valid: true, disposable: true) if address.disposable?

    true
  end

  private

  def raise_invalid(payload)
    raise CustomExceptions::Account::InvalidEmail, payload
  end

  def domain_blocked?
    domain = email.split('@').last&.downcase
    blocked_domains.any? { |blocked| domain.match?(blocked.downcase) }
  end

  def blocked_domains
    domains = GlobalConfigService.load('BLOCKED_EMAIL_DOMAINS', '')
    return [] if domains.blank?

    domains.split("\n").map(&:strip)
  end
end
