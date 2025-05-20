class ConversationHandoff::SendHandoffNotificationsJob < ApplicationJob
  queue_as :default

  def perform(conversation)
    return if conversation.blank?

    begin
      AdministratorNotifications::ConversationHandoffMailer.notify_handoff(conversation).deliver_later
      AgentNotifications::ConversationHandoffMailer.notify_handoff(conversation).deliver_later
    rescue StandardError => e
      Rails.logger.error("Failed to send handoff notifications: #{e.message}")
    end
  end
end
