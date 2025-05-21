# frozen_string_literal: true

class Account::SignUpAccount::SignUpEmailValidationService
  include CustomExceptions::Account
  attr_reader :email

  def initialize(email)
    @email = email
  end

  def validate
    address = ValidEmail2::Address.new(email)

    raise InvalidEmail.new({ valid: false, disposable: nil }) unless address.valid?

    raise InvalidEmail.new({ domain_blocked: true }) if domain_blocked?

    raise InvalidEmail.new({ valid: true, disposable: true }) if address.disposable?

    true
  end

  def business_email?
    !domain_blocked?
  end

  def domain_blocked?
    domain = email.split('@').last&.downcase
    blocked_domains.any? { |blocked_domain| domain.match?(blocked_domain.downcase) }
  end

  private

  def blocked_domains
    domains = GlobalConfigService.load('BLOCKED_EMAIL_DOMAINS', '')
    return [] if domains.blank?

    domains.split("\n").map(&:strip)
  end
end
