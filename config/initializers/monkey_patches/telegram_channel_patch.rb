# Monkey patch for Telegram::IncomingMessageService
#
# This service is responsible for processing incoming Telegram messages:
# it creates a contact, finds or creates a conversation, and saves the message.
#
# Purpose of the patch: automatically set the custom attribute channel_type = "telegram"
# on a conversation when it is created or updated from a Telegram source.
# This allows conversations to be filtered and identified by their channel origin.
#
# Date modified: 12.05.2026

module TelegramIncomingMessageServicePatch
  TELEGRAM_CUSTOM_ATTRIBUTE_KEY = 'channel_type'.freeze
  TELEGRAM_CHANNEL_VALUE = 'telegram'.freeze

  def perform
    result = super
    set_telegram_custom_attribute
    result
  end

  private

  def set_telegram_custom_attribute
    return unless @conversation

    account = @conversation.account
    return unless account

    contact = @conversation.contact
    return unless contact

    ensure_attribute_exists(account)

    existing = contact.custom_attributes || {}
    return if existing[TELEGRAM_CUSTOM_ATTRIBUTE_KEY].present?

    contact.update!(
      custom_attributes: existing.merge(TELEGRAM_CUSTOM_ATTRIBUTE_KEY => TELEGRAM_CHANNEL_VALUE)
    )
  rescue StandardError => e
    Rails.logger.error("[TelegramIncomingMessageServicePatch] Failed to set custom attribute: #{e.message}")
  end

  def ensure_attribute_exists(account)
    return if CustomAttributeDefinition.exists?(
      account: account,
      attribute_key: TELEGRAM_CUSTOM_ATTRIBUTE_KEY,
      attribute_model: :contact_attribute
    )

    CustomAttributeDefinition.create!(
      account: account,
      attribute_key: TELEGRAM_CUSTOM_ATTRIBUTE_KEY,
      attribute_display_name: 'Channel Type',
      attribute_display_type: :text,
      attribute_model: :contact_attribute
    )
  rescue ActiveRecord::RecordNotUnique
    # another request created the definition concurrently; nothing to do
  end
end

Rails.application.config.after_initialize do
  Telegram::IncomingMessageService.prepend(TelegramIncomingMessageServicePatch)
end
