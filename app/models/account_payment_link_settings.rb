# == Schema Information
#
# Table name: account_payment_link_settings
#
#  id                 :bigint           not null, primary key
#  default_currency   :string           default("KWD")
#  default_provider   :string
#  notification_email :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :bigint           not null
#
# Indexes
#
#  index_account_payment_link_settings_on_account_id  (account_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class AccountPaymentLinkSettings < ApplicationRecord
  belongs_to :account

  validates :account_id, presence: true, uniqueness: true
  validates :default_provider, inclusion: { in: AccountCatalogSettings::PAYMENT_PROVIDERS }, allow_nil: true
  validate :validate_notification_emails
  validate :validate_currency_for_provider

  def notification_email_list
    notification_email.to_s.split(',').map(&:strip).reject(&:blank?)
  end

  def available_currencies
    case default_provider
    when 'payzah' then AccountCatalogSettings::PAYZAH_CURRENCIES
    when 'tap' then AccountCatalogSettings::TAP_CURRENCIES
    else AccountCatalogSettings::ALL_CURRENCIES
    end
  end

  private

  def validate_notification_emails
    return if notification_email.blank?

    notification_email_list.each do |email|
      next if email.match?(URI::MailTo::EMAIL_REGEXP)

      errors.add(:notification_email, "contains invalid email: #{email}")
    end
  end

  def validate_currency_for_provider
    return if default_currency.blank?
    return if available_currencies.include?(default_currency)

    errors.add(:default_currency, "is not supported by #{default_provider || 'this configuration'}")
  end
end
