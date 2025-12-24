class AgentStatusNotificationJob < ApplicationJob
  queue_as :low

  def perform(agent_id, account_id, new_status, old_status) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    agent = User.find_by(id: agent_id)
    account = Account.find_by(id: account_id)

    return unless agent && account

    # Get notification settings
    settings = account.custom_attributes&.dig('agent_status_notifications')
    return unless settings && settings['enabled'] == true

    # Get recipient emails
    recipient_emails = settings['recipient_emails'] || []
    return if recipient_emails.empty?

    # Determine which email to send based on status transition
    # Only send for online <-> offline transitions (skip busy)
    return if new_status == 'busy' || old_status == 'busy'

    # Send emails to all recipients
    recipient_emails.each do |email|
      if new_status == 'online' && old_status == 'offline'
        AdminNotifications::AgentStatusMailer.agent_went_online(agent, account, email).deliver_later
      elsif new_status == 'offline' && old_status == 'online'
        AdminNotifications::AgentStatusMailer.agent_went_offline(agent, account, email).deliver_later
      end
    end
  end
end
