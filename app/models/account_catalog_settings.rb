# == Schema Information
#
# Table name: account_catalog_settings
#
#  id                       :bigint           not null, primary key
#  currency                 :string           default("SAR")
#  enabled                  :boolean          default(FALSE), not null
#  order_notification_email :string
#  payment_provider         :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  account_id               :bigint           not null
#
# Indexes
#
#  index_account_catalog_settings_on_account_id  (account_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class AccountCatalogSettings < ApplicationRecord
  PAYMENT_PROVIDERS = %w[tap payzah].freeze
  TAP_CURRENCIES = %w[KWD USD EUR GBP SAR AED BHD QAR OMR EGP JOD].freeze
  PAYZAH_CURRENCIES = %w[KWD].freeze
  ALL_CURRENCIES = %w[KWD SAR USD AED EUR GBP BHD QAR OMR EGP JOD].freeze

  belongs_to :account

  validates :account_id, presence: true, uniqueness: true
  validates :payment_provider, inclusion: { in: PAYMENT_PROVIDERS }, allow_nil: true
  validate :validate_order_notification_emails
  validate :validate_currency_for_provider

  after_save :sync_currency_to_account

  def catalog_configured?
    enabled?
  end

  def notification_email_list
    order_notification_email.to_s.split(',').map(&:strip).reject(&:blank?)
  end

  def available_currencies
    case payment_provider
    when 'payzah' then PAYZAH_CURRENCIES
    when 'tap' then TAP_CURRENCIES
    else ALL_CURRENCIES
    end
  end

  private

  def validate_order_notification_emails
    return if order_notification_email.blank?

    notification_email_list.each do |email|
      next if email.match?(URI::MailTo::EMAIL_REGEXP)

      errors.add(:order_notification_email, "contains invalid email: #{email}")
    end
  end

  def validate_currency_for_provider
    return if currency.blank?
    return if available_currencies.include?(currency)

    errors.add(:currency, "is not supported by #{payment_provider || 'this configuration'}")
  end

  def sync_currency_to_account
    return if account.catalog_currency == currency

    account.update_column(:settings, account.settings.merge('catalog_currency' => currency))
  end
end
