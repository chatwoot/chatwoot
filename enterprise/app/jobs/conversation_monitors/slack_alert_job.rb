class ConversationMonitors::SlackAlertJob < ApplicationJob
  self.enqueue_after_transaction_commit = true

  queue_as :medium

  def perform(monitor_id, conversation_id)
    monitor = ConversationMonitors::Monitor.active.find_by(id: monitor_id)
    return if monitor&.slack_channel_id.blank?

    hook = monitor.account.hooks.find_by(app_id: 'slack')
    conversation = monitor.account.conversations.find_by(id: conversation_id)
    return unless hook && conversation

    ConversationMonitors::SlackAlertService.new(monitor: monitor, conversation: conversation, hook: hook).perform
  end
end
