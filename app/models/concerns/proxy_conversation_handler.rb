module ProxyConversationHandler
  extend ActiveSupport::Concern

  included do
    after_update_commit :close_linked_conversation_if_resolved
  end

  private

  def close_linked_conversation_if_resolved
    return unless saved_change_to_status?
    return unless resolved?

    linked_id = additional_attributes&.dig('linked_conversation_id')
    return if linked_id.blank?

    linked = Conversation.find_by(id: linked_id)
    return if linked.blank?
    return if linked.resolved?

    linked.resolved!
  rescue StandardError => e
    Rails.logger.error("ProxyConversationHandler: failed to close linked conversation #{linked_id}: #{e.message}")
  end
end
