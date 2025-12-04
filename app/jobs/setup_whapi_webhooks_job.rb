# frozen_string_literal: true

class SetupWhapiWebhooksJob < ApplicationJob
  queue_as :default

  def perform(inbox_id)
    inbox = Inbox.find(inbox_id)
    return unless inbox.channel.is_a?(Channel::Whatsapp)
    return unless inbox.channel.provider == 'whatsapp_light'

    Whatsapp::WhapiWebhookSetupService.new(
      channel: inbox.channel,
      inbox_id: inbox.id
    ).perform

    Rails.logger.info "[WHATSAPP LIGHT] Webhooks setup completed for inbox #{inbox_id}"
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP LIGHT] Webhooks setup failed for inbox #{inbox_id}: #{e.message}"
    raise e
  end
end
