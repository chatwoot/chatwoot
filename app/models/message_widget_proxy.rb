module MessageWidgetProxy
  extend ActiveSupport::Concern

  included do
    after_create_commit :mirror_outgoing_to_linked_widget_conversation
  end

  private

  def mirror_outgoing_to_linked_widget_conversation
    return unless outgoing?
    return unless sender.is_a?(User)
    return if private?
    return if source_id&.start_with?('mirror_')
    return if source_id&.start_with?('pending_mirror_')

    proxy_conversation = find_proxy_conversation_linked_to(conversation)
    return if proxy_conversation.blank?
    return unless proxy_conversation.proxied?
    return if content.blank? && attachments.empty?

    return if mirrored_message_exists?(proxy_conversation, id)

    mirror_message_to_conversation(proxy_conversation, additional_attributes: { 'mirrored_from_message_id' => id.to_s })

    telegram_conversation = find_source_telegram_conversation_linked_to(proxy_conversation)
    mirror_message_to_conversation(
      telegram_conversation,
      additional_attributes: { 'mirrored_from_message_id' => id.to_s },
      skip_if_already_mirrored: true
    )

  rescue StandardError => e
    Rails.logger.error("MessageWidgetProxy mirror_outgoing_to_linked_widget_conversation failed: #{e.class} - #{e.message}")
  end

  def mirror_message_to_conversation(target_conversation, additional_attributes:, skip_if_already_mirrored: false)
    return if target_conversation.blank?
    return if content.blank? && attachments.empty?
    return if skip_if_already_mirrored && mirrored_message_exists?(target_conversation, id)

    mirrored = target_conversation.messages.new(
      account_id: target_conversation.account_id,
      inbox_id: target_conversation.inbox_id,
      message_type: :outgoing,
      content: content,
      sender: sender,
      additional_attributes: additional_attributes,
      source_id: "pending_mirror_#{id}"
    )
    mirrored.save!(validate: false)

    mirror_attachments_to_message(mirrored)

    mirrored.update_column(:source_id, nil)
    mirrored.reload

    if mirrored.attachments.present?
      ::SendReplyJob.set(wait: 2.seconds).perform_later(mirrored.id)
    else
      ::SendReplyJob.perform_later(mirrored.id)
    end

    Rails.configuration.dispatcher.dispatch(
      Events::Types::MESSAGE_CREATED,
      Time.zone.now,
      message: mirrored,
      performed_by: nil
    )

    mirrored
  end

  def mirror_attachments_to_message(target_message)
    attachments.each do |original_attachment|
      next unless original_attachment.file.attached?

      new_att = target_message.attachments.create!(
        account_id: target_message.account_id,
        file_type: original_attachment.file_type
      )
      new_att.file.attach(original_attachment.file.blob)
      new_att.save!
    rescue StandardError => e
      Rails.logger.error("MessageWidgetProxy: failed to mirror attachment #{original_attachment.id}: #{e.message}")
    end
  end

  def mirrored_message_exists?(target_conversation, source_message_id)
    target_conversation.messages.where(
      "additional_attributes->>'mirrored_from_message_id' = ?", source_message_id.to_s
    ).exists?
  end

  def find_proxy_conversation_linked_to(source_conversation)
    source_widget_id = source_conversation.additional_attributes&.dig('source_widget_id')
    if source_widget_id.present?
      widget = Conversation.find_by(id: source_widget_id)
      return widget if widget&.proxied?
    end
  
    visited = Set.new([source_conversation.id])
    current = source_conversation
  
    loop do
      attrs = current.additional_attributes || {}
      linked_id = attrs['linked_conversation_id']
      break if linked_id.blank? || visited.include?(linked_id)
  
      linked = Conversation.find_by(id: linked_id)
      break if linked.blank?
  
      visited << current.id
      current = linked
  
      break if current.proxied?
    end
  
    return nil if current.id == source_conversation.id
    return nil unless current.proxied?
  
    current
  end

  def find_source_telegram_conversation_linked_to(widget_conversation)
    tg_id = widget_conversation.additional_attributes&.dig('source_telegram_conversation_id')
    return nil if tg_id.blank?

    tg_conversation = Conversation.find_by(id: tg_id)
    return nil if tg_conversation.blank?
    return nil unless tg_conversation.inbox.channel_type == 'Channel::Telegram'

    tg_conversation
  rescue StandardError => e
    Rails.logger.error("MessageWidgetProxy: failed to find source telegram conversation #{tg_id}: #{e.message}")
    nil
  end
end
