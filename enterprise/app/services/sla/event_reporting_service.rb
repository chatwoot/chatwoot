class Sla::EventReportingService
  pattr_initialize [:applied_sla!, :event_type!, :event_data!]

  def perform
    create_reporting_event
    trigger_external_webhooks
    update_metrics_cache
    schedule_compliance_reports if should_generate_reports?
  end

  private

  def create_reporting_event
    ReportingEvent.create!(
      account: applied_sla.account,
      conversation: applied_sla.conversation,
      inbox: applied_sla.conversation.inbox,
      user: applied_sla.conversation.assignee,
      name: "sla.#{event_type}",
      value: event_value,
      value_in_business_hours: business_hours_value,
      event_start_time: event_start_time,
      event_end_time: Time.current,
      custom_attributes: {
        sla_policy_id: applied_sla.sla_policy_id,
        sla_policy_name: applied_sla.sla_policy.name,
        department_id: applied_sla.conversation.queue&.department_id,
        department_name: applied_sla.conversation.queue&.department&.name,
        queue_id: applied_sla.conversation.queue_id,
        queue_name: applied_sla.conversation.queue&.name,
        breach_type: event_type,
        threshold: threshold_value,
        actual_time: event_value,
        business_hours_only: applied_sla.sla_policy.only_during_business_hours
      }
    )
  end

  def event_value
    case event_type
    when 'first_response'
      applied_sla.conversation.first_reply_created_at&.to_i - applied_sla.conversation.created_at.to_i
    when 'next_response'
      Time.current.to_i - (applied_sla.conversation.waiting_since&.to_i || applied_sla.conversation.created_at.to_i)
    when 'resolution'
      if applied_sla.conversation.resolved?
        applied_sla.conversation.resolved_at.to_i - applied_sla.conversation.created_at.to_i
      else
        Time.current.to_i - applied_sla.conversation.created_at.to_i
      end
    else
      0
    end
  end

  def business_hours_value
    return event_value unless applied_sla.sla_policy.only_during_business_hours

    # Calculate value considering only business hours
    # This would require business hours logic from account settings
    calculate_business_hours_duration
  end

  def calculate_business_hours_duration
    # Simplified business hours calculation
    # In a real implementation, this would use the account's business hours settings
    business_hours_ratio = 8.0 / 24.0 # Assuming 8 hours per day
    (event_value * business_hours_ratio).to_i
  end

  def event_start_time
    case event_type
    when 'first_response'
      applied_sla.conversation.created_at
    when 'next_response'
      applied_sla.conversation.waiting_since || applied_sla.conversation.created_at
    when 'resolution'
      applied_sla.conversation.created_at
    else
      applied_sla.created_at
    end
  end

  def threshold_value
    case event_type
    when 'first_response'
      applied_sla.sla_policy.first_response_time_threshold
    when 'next_response'
      applied_sla.sla_policy.next_response_time_threshold
    when 'resolution'
      applied_sla.sla_policy.resolution_time_threshold
    else
      0
    end
  end

  def trigger_external_webhooks
    webhook_payload = build_webhook_payload

    # Account-specific webhooks
    applied_sla.account.webhooks.active.each do |webhook|
      next unless webhook_matches_filters?(webhook)
      
      Sla::WebhookJob.perform_later(webhook.url, webhook_payload)
    end

    # Department-specific webhooks
    if applied_sla.conversation.queue&.department
      department_webhooks = applied_sla.conversation.queue.department.routing_rules&.dig('webhooks') || []
      department_webhooks.each do |webhook_url|
        Sla::WebhookJob.perform_later(webhook_url, webhook_payload)
      end
    end
  end

  def build_webhook_payload
    {
      event: "sla.#{event_type}",
      timestamp: Time.current.iso8601,
      account: {
        id: applied_sla.account_id,
        name: applied_sla.account.name
      },
      conversation: {
        id: applied_sla.conversation.id,
        display_id: applied_sla.conversation.display_id,
        status: applied_sla.conversation.status,
        priority: applied_sla.conversation.priority,
        created_at: applied_sla.conversation.created_at.iso8601,
        assignee: applied_sla.conversation.assignee&.slice(:id, :name, :email),
        contact: applied_sla.conversation.contact.slice(:id, :name, :email),
        inbox: applied_sla.conversation.inbox.slice(:id, :name, :channel_type)
      },
      sla_policy: applied_sla.sla_policy.push_event_data,
      department: applied_sla.conversation.queue&.department&.push_event_data,
      queue: applied_sla.conversation.queue&.push_event_data,
      applied_sla: applied_sla.push_event_data.merge({
        event_type: event_type,
        threshold: threshold_value,
        actual_time: event_value,
        is_breach: event_value > threshold_value,
        business_hours_duration: business_hours_value
      }),
      event_data: event_data
    }
  end

  def webhook_matches_filters?(webhook)
    return true unless webhook.settings.present?

    filters = webhook.settings['sla_filters'] || {}
    
    # Filter by event type
    if filters['event_types'].present?
      return false unless filters['event_types'].include?(event_type)
    end

    # Filter by department
    if filters['departments'].present?
      department_id = applied_sla.conversation.queue&.department_id
      return false unless filters['departments'].include?(department_id)
    end

    # Filter by breach status
    if filters['only_breaches'].present? && filters['only_breaches'] == true
      return false unless event_value > threshold_value
    end

    true
  end

  def update_metrics_cache
    # Update Redis cache with real-time SLA metrics
    cache_key = "sla_metrics:#{applied_sla.account_id}"
    
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      calculate_account_sla_metrics
    end

    # Invalidate cache to force recalculation
    Rails.cache.delete(cache_key)

    # Update department-specific metrics
    if applied_sla.conversation.queue&.department
      dept_cache_key = "sla_metrics:#{applied_sla.account_id}:department:#{applied_sla.conversation.queue.department_id}"
      Rails.cache.delete(dept_cache_key)
    end

    # Update queue-specific metrics  
    if applied_sla.conversation.queue
      queue_cache_key = "sla_metrics:#{applied_sla.account_id}:queue:#{applied_sla.conversation.queue_id}"
      Rails.cache.delete(queue_cache_key)
    end
  end

  def calculate_account_sla_metrics
    # This would calculate comprehensive metrics for the account
    # Including breach rates, average response times, etc.
    {
      total_conversations: applied_sla.account.conversations.count,
      sla_breach_rate: calculate_breach_rate,
      average_response_time: calculate_average_response_time,
      last_updated: Time.current.iso8601
    }
  end

  def calculate_breach_rate
    total_with_sla = applied_sla.account.applied_slas.count
    return 0 if total_with_sla.zero?

    breached = applied_sla.account.applied_slas.where(sla_status: %i[missed active_with_misses]).count
    (breached.to_f / total_with_sla * 100).round(2)
  end

  def calculate_average_response_time
    applied_sla.account.conversations
               .joins(:messages)
               .where(messages: { message_type: :outgoing })
               .average('EXTRACT(EPOCH FROM (messages.created_at - conversations.created_at))')&.to_f || 0
  end

  def should_generate_reports?
    # Generate reports for significant events or on schedule
    case event_type
    when 'resolution'
      true # Always generate reports when conversations are resolved
    when 'first_response', 'next_response'
      event_value > threshold_value # Generate reports for breaches
    else
      false
    end
  end

  def schedule_compliance_reports
    # Schedule compliance report generation for this department/queue
    Sla::ComplianceReportJob.perform_later(
      applied_sla.account_id,
      applied_sla.conversation.queue&.department_id,
      applied_sla.conversation.queue_id
    )
  end
end