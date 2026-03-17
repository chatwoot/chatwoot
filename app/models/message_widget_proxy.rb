module MessageWidgetProxy
  extend ActiveSupport::Concern

  included do
    after_create_commit :mirror_outgoing_to_linked_widget_conversation
  end

  private

  def mirror_outgoing_to_linked_widget_conversation
    return unless outgoing?
    return unless sender.is_a?(User)
    return if Thread.current[:mirroring_widget_message]

    widget_conversation = find_widget_conversation_linked_to(conversation)
    return if widget_conversation.blank?
    return if content.blank?

    Thread.current[:mirroring_widget_message] = true

    params = {
      content: content,
      message_type: 'outgoing',
      source_id: nil
    }

    Messages::MessageBuilder.new(sender, widget_conversation, params).perform
  rescue StandardError => e
    Rails.logger.error(
      "MessageWidgetProxy mirror_outgoing_to_linked_widget_conversation failed: #{e.class} - #{e.message}"
    )
  ensure
    Thread.current[:mirroring_widget_message] = nil
  end

  def find_widget_conversation_linked_to(source_conversation)
    attrs = source_conversation.additional_attributes || {}

    linked_id = attrs['linked_conversation_id']
    return nil if linked_id.blank?

    linked = Conversation.find_by(id: linked_id)
    return nil if linked.blank?

    return linked if linked.inbox.channel_type == 'Channel::WebWidget'

    nil
  end
end
