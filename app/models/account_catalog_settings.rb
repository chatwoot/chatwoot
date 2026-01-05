class AccountCatalogSettings < ApplicationRecord
  PAYMENT_PROVIDERS = %w[tap payzah].freeze
  TAP_CURRENCIES = %w[KWD USD EUR GBP SAR AED BHD QAR OMR EGP JOD].freeze
  PAYZAH_CURRENCIES = %w[KWD].freeze
  ALL_CURRENCIES = %w[KWD SAR USD AED EUR GBP BHD QAR OMR EGP JOD].freeze

  belongs_to :account

  validates :account_id, presence: true, uniqueness: true
  validates :payment_provider, inclusion: { in: PAYMENT_PROVIDERS }, allow_nil: true
  validate :validate_currency_for_provider

  def catalog_configured?
    enabled?
  end

  def available_currencies
    case payment_provider
    when 'payzah' then PAYZAH_CURRENCIES
    when 'tap' then TAP_CURRENCIES
    else ALL_CURRENCIES
    end
  end

  private

  def validate_currency_for_provider
    return if currency.blank?
    return if available_currencies.include?(currency)

    errors.add(:currency, "is not supported by #{payment_provider || 'this configuration'}")
  end
end
