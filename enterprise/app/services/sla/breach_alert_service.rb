class Sla::BreachAlertService
  pattr_initialize [:applied_sla!, :breach_type!]

  def perform
    send_email_notifications
    send_slack_notifications if slack_integration_available?
    trigger_webhook_notifications
    create_internal_notification
    escalate_to_supervisors if should_escalate?
  end

  private

  def send_email_notifications
    # Send to assigned agent
    if applied_sla.conversation.assignee.present?
      Enterprise::AgentNotifications::ConversationNotificationsMailer
        .send("sla_missed_#{breach_type}", applied_sla.conversation, applied_sla.conversation.assignee)
        .deliver_later
    end

    # Send to queue agents if conversation is in a queue
    if applied_sla.conversation.queue.present?
      applied_sla.conversation.queue.agents.each do |agent|
        Enterprise::AgentNotifications::ConversationNotificationsMailer
          .send("sla_missed_#{breach_type}", applied_sla.conversation, agent)
          .deliver_later
      end
    end

    # Send to department supervisors
    send_supervisor_notifications
  end

  def send_supervisor_notifications
    return unless applied_sla.conversation.queue&.department

    supervisors = User.joins(:account_users)
                      .where(account_users: { 
                        account_id: applied_sla.account_id, 
                        role: ['administrator', 'supervisor'] 
                      })

    supervisors.each do |supervisor|
      Enterprise::AgentNotifications::ConversationNotificationsMailer
        .send("sla_missed_#{breach_type}", applied_sla.conversation, supervisor)
        .deliver_later
    end
  end

  def send_slack_notifications
    return unless applied_sla.account.slack_integration&.active?

    SlackNotificationJob.perform_later(
      applied_sla.conversation,
      applied_sla.account,
      "SLA Breach Alert: #{breach_type.upcase} threshold exceeded for conversation ##{applied_sla.conversation.display_id}"
    )
  end

  def trigger_webhook_notifications
    webhook_data = {
      event: 'sla_breach',
      data: {
        conversation_id: applied_sla.conversation.id,
        display_id: applied_sla.conversation.display_id,
        breach_type: breach_type,
        sla_policy: applied_sla.sla_policy.push_event_data,
        department: applied_sla.conversation.queue&.department&.push_event_data,
        queue: applied_sla.conversation.queue&.push_event_data,
        applied_sla: applied_sla.push_event_data,
        timestamp: Time.current.iso8601
      }
    }

    # Trigger account webhooks
    applied_sla.account.webhooks.where(active: true).each do |webhook|
      WebhookJob.perform_later(webhook.url, webhook_data)
    end
  end

  def create_internal_notification
    Notification.create!(
      notification_type: 'sla_breach',
      primary_actor: applied_sla.conversation,
      secondary_actor: applied_sla.sla_policy,
      account: applied_sla.account,
      user: applied_sla.conversation.assignee,
      notification_subscriptions_attributes: notification_subscriptions_params
    )
  rescue => e
    Rails.logger.error "Failed to create SLA breach notification: #{e.message}"
  end

  def notification_subscriptions_params
    subscriptions = []
    
    # Assigned agent
    if applied_sla.conversation.assignee.present?
      subscriptions << { user_id: applied_sla.conversation.assignee_id }
    end

    # Queue agents
    if applied_sla.conversation.queue.present?
      applied_sla.conversation.queue.agents.pluck(:id).each do |agent_id|
        subscriptions << { user_id: agent_id }
      end
    end

    subscriptions
  end

  def should_escalate?
    case breach_type
    when 'first_response_time'
      true # Always escalate first response breaches
    when 'next_response_time'
      applied_sla.sla_events.where(event_type: 'nrt').count >= 2
    when 'resolution_time'
      time_since_creation = Time.current - applied_sla.conversation.created_at
      time_since_creation > 24.hours # Escalate if resolution breach and conversation is older than 24h
    else
      false
    end
  end

  def escalate_to_supervisors
    department = applied_sla.conversation.queue&.department
    return unless department

    EscalationJob.perform_later(
      applied_sla.conversation,
      breach_type,
      department.id
    )
  end

  def slack_integration_available?
    applied_sla.account.integrations&.find_by(name: 'slack')&.active?
  end
end