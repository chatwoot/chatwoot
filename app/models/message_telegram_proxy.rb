module MessageTelegramProxy
  extend ActiveSupport::Concern

  included do
    after_create_commit :mirror_incoming_telegram_to_linked
  end

  private

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity -- mirrors a Telegram message incl. attachments
  def mirror_incoming_telegram_to_linked
    return unless incoming?
    return if source_id&.start_with?('mirror_')
    return unless conversation.inbox.channel_type == 'Channel::Telegram'

    linked_id = conversation.additional_attributes&.dig('linked_conversation_id')
    return if linked_id.blank?

    target_conversation = Conversation.find_by(id: linked_id)
    return if target_conversation.blank?
    return if content.blank? && attachments.empty?

    mirrored = target_conversation.messages.new(
      account_id: target_conversation.account_id,
      inbox_id: target_conversation.inbox_id,
      message_type: :incoming,
      content: content,
      sender: conversation.contact,
      source_id: "mirror_tg_#{id}"
    )
    mirrored.save!(validate: false)

    attachments.each do |original_attachment|
      next unless original_attachment.file.attached?

      new_att = mirrored.attachments.create!(
        account_id: mirrored.account_id,
        file_type: original_attachment.file_type
      )
      new_att.file.attach(original_attachment.file.blob)
      new_att.save!
    rescue StandardError => e
      Rails.logger.error("MessageTelegramProxy: failed to mirror attachment #{original_attachment.id}: #{e.message}")
    end

    mirrored.reload

    Rails.configuration.dispatcher.dispatch(
      Events::Types::MESSAGE_CREATED,
      Time.zone.now,
      message: mirrored,
      performed_by: nil
    )

    Rails.logger.info("[TelegramProxy] mirrored incoming tg message #{id} → conversation #{target_conversation.id}")
  rescue StandardError => e
    Rails.logger.error("[TelegramProxy] mirror_incoming_telegram_to_linked failed: #{e.class} - #{e.message}")
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
end
