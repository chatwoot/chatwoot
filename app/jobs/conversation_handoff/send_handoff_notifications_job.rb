class ConversationHandoff::SendHandoffNotificationsJob < ApplicationJob
  queue_as :default

  def perform(conversation)
    return if conversation.blank?

    begin
      # Generate conversation summary
      Conversations::SummaryService.new(conversation: conversation, force_refresh: true, skip_rate_limit: true).perform

      # Send email notifications
      AdministratorNotifications::ConversationHandoffMailer.notify_handoff(conversation).deliver_later
      AgentNotifications::ConversationHandoffMailer.notify_handoff(conversation).deliver_later

      # Send SMS notifications
      Sms::HandoffNotificationService.new(conversation).perform
    rescue StandardError => e
      Rails.logger.error("Failed to send handoff notifications: #{e.message}")
      SlackNotifierService.new(
        text: "Handoff failed. Failed to send handoff notifications: #{e.message}"
      )
    end
  end
end
