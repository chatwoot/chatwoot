# frozen_string_literal: true

module WhatsappMigrationNotifiable
  extend ActiveSupport::Concern

  included do
    after_update :notify_whatsapp_provider_change, if: :saved_change_to_provider?
  end

  private

  def notify_whatsapp_provider_change
    return unless channel_type == 'Channel::Whatsapp'

    account_admin = account.administrators.first
    return unless account_admin

    if provider_changed_to_official?
      WhatsappMigrationMailer.official_api_confirmation(account, account_admin, self).deliver_later
    elsif provider_changed_to_unofficial?
      WhatsappMigrationMailer.unofficial_risk_notification(account, account_admin, self).deliver_later
    end
  end

  def provider_changed_to_official?
    provider_was != 'whatsapp_cloud' && provider == 'whatsapp_cloud'
  end

  def provider_changed_to_unofficial?
    provider_was == 'whatsapp_cloud' && provider != 'whatsapp_cloud'
  end
end