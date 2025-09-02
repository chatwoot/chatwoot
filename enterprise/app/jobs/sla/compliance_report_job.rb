class Sla::ComplianceReportJob < ApplicationJob
  queue_as :low

  def perform(account_id, department_id = nil, queue_id = nil)
    @account = Account.find(account_id)
    @department = Department.find_by(id: department_id) if department_id
    @queue = Queue.find_by(id: queue_id) if queue_id

    generate_compliance_report
    send_compliance_notifications if should_notify?
  end

  private

  def generate_compliance_report
    @report_data = {
      account_id: @account.id,
      department_id: @department&.id,
      queue_id: @queue&.id,
      generated_at: Time.current.iso8601,
      period: report_period,
      metrics: calculate_compliance_metrics,
      trends: calculate_trends,
      recommendations: generate_recommendations
    }

    # Store the report for later access
    store_compliance_report
  end

  def report_period
    {
      start_date: 30.days.ago.beginning_of_day.iso8601,
      end_date: Time.current.end_of_day.iso8601,
      duration_days: 30
    }
  end

  def calculate_compliance_metrics
    scope = base_applied_slas_scope
    
    {
      total_conversations: scope.count,
      sla_compliant: scope.where(sla_status: %i[active hit]).count,
      sla_breached: scope.where(sla_status: %i[missed active_with_misses]).count,
      compliance_rate: calculate_compliance_rate(scope),
      average_response_time: calculate_average_response_time(scope),
      average_resolution_time: calculate_average_resolution_time(scope),
      breach_breakdown: calculate_breach_breakdown(scope)
    }
  end

  def base_applied_slas_scope
    scope = @account.applied_slas.where(created_at: 30.days.ago..Time.current)
    
    if @queue
      scope = scope.joins(:conversation).where(conversations: { queue_id: @queue.id })
    elsif @department
      scope = scope.joins(conversation: :queue).where(queues: { department_id: @department.id })
    end

    scope
  end

  def calculate_compliance_rate(scope)
    total = scope.count
    return 100.0 if total.zero?

    compliant = scope.where(sla_status: %i[active hit]).count
    (compliant.to_f / total * 100).round(2)
  end

  def calculate_average_response_time(scope)
    conversations = scope.joins(:conversation)
                        .joins('JOIN messages ON messages.conversation_id = conversations.id')
                        .where(messages: { message_type: :outgoing })
                        .average('EXTRACT(EPOCH FROM (messages.created_at - conversations.created_at))')

    (conversations || 0).to_f
  end

  def calculate_average_resolution_time(scope)
    resolved_conversations = scope.joins(:conversation)
                                 .where(conversations: { status: :resolved })
                                 .average('EXTRACT(EPOCH FROM (conversations.updated_at - conversations.created_at))')

    (resolved_conversations || 0).to_f
  end

  def calculate_breach_breakdown(scope)
    breached_slas = scope.joins(:sla_events)
                        .group('sla_events.event_type')
                        .count

    {
      first_response_breaches: breached_slas['frt'] || 0,
      next_response_breaches: breached_slas['nrt'] || 0,
      resolution_breaches: breached_slas['rt'] || 0
    }
  end

  def calculate_trends
    current_metrics = calculate_compliance_metrics
    previous_scope = base_applied_slas_scope.where(created_at: 60.days.ago..30.days.ago)
    previous_total = previous_scope.count
    
    return {} if previous_total.zero?

    previous_compliant = previous_scope.where(sla_status: %i[active hit]).count
    previous_compliance_rate = (previous_compliant.to_f / previous_total * 100).round(2)

    {
      compliance_rate_change: current_metrics[:compliance_rate] - previous_compliance_rate,
      trend_direction: current_metrics[:compliance_rate] > previous_compliance_rate ? 'improving' : 'declining'
    }
  end

  def generate_recommendations
    recommendations = []
    metrics = @report_data[:metrics]
    
    if metrics[:compliance_rate] < 80
      recommendations << "SLA compliance rate is below 80%. Consider reviewing queue capacity and agent availability."
    end

    if metrics[:breach_breakdown][:first_response_breaches] > 10
      recommendations << "High number of first response breaches. Consider auto-assignment rules or increasing agent coverage."
    end

    if metrics[:breach_breakdown][:resolution_breaches] > 5
      recommendations << "Multiple resolution time breaches detected. Review complex ticket escalation procedures."
    end

    if @queue && @queue.capacity_percentage > 90
      recommendations << "Queue is operating at high capacity (#{@queue.capacity_percentage}%). Consider increasing max_capacity or adding more agents."
    end

    recommendations
  end

  def store_compliance_report
    # Store in Redis for quick access
    cache_key = compliance_report_cache_key
    Rails.cache.write(cache_key, @report_data, expires_in: 24.hours)

    # Also store in database for historical purposes if needed
    create_compliance_record if should_store_permanently?
  end

  def compliance_report_cache_key
    parts = ["sla_compliance_report", @account.id]
    parts << "department_#{@department.id}" if @department
    parts << "queue_#{@queue.id}" if @queue
    parts << Date.current.strftime('%Y_%m_%d')
    
    parts.join(':')
  end

  def should_store_permanently?
    # Store permanently for monthly reports or when compliance is poor
    Date.current.day == 1 || @report_data[:metrics][:compliance_rate] < 70
  end

  def create_compliance_record
    # This would create a database record for permanent storage
    # Implementation depends on if you want to add a ComplianceReport model
  end

  def should_notify?
    metrics = @report_data[:metrics]
    
    # Notify if compliance is poor or trending downward
    metrics[:compliance_rate] < 80 || 
    (@report_data[:trends][:trend_direction] == 'declining' && 
     @report_data[:trends][:compliance_rate_change] < -10)
  end

  def send_compliance_notifications
    # Email department managers and supervisors
    notify_department_managers
    
    # Slack notifications if configured
    send_slack_compliance_alert if slack_notifications_enabled?
    
    # Webhook notifications
    trigger_compliance_webhooks
  end

  def notify_department_managers
    managers = find_department_managers
    
    managers.each do |manager|
      SlaComplianceMailer.compliance_report(manager, @report_data).deliver_later
    end
  end

  def find_department_managers
    scope = User.joins(:account_users)
               .where(account_users: { 
                 account_id: @account.id, 
                 role: ['administrator', 'supervisor'] 
               })

    # Filter by department if specified
    if @department
      # This would require additional logic to link users to departments
      # For now, return all supervisors
    end

    scope
  end

  def slack_notifications_enabled?
    @account.integrations.find_by(name: 'slack')&.active? &&
    (@department&.routing_rules&.dig('slack_compliance_alerts') ||
     @queue&.routing_rules&.dig('slack_compliance_alerts'))
  end

  def send_slack_compliance_alert
    channel = determine_slack_channel
    message = format_slack_compliance_message
    
    Sla::SlackNotificationJob.perform_later(nil, @account, message)
  end

  def determine_slack_channel
    @queue&.routing_rules&.dig('slack_channel') ||
    @department&.routing_rules&.dig('slack_channel') ||
    '#sla-alerts'
  end

  def format_slack_compliance_message
    metrics = @report_data[:metrics]
    scope_name = @queue&.name || @department&.name || @account.name
    
    "📊 **SLA Compliance Report - #{scope_name}**\n" \
    "Compliance Rate: #{metrics[:compliance_rate]}%\n" \
    "Total Conversations: #{metrics[:total_conversations]}\n" \
    "Breached: #{metrics[:sla_breached]}\n" \
    "Trend: #{@report_data[:trends][:trend_direction]&.capitalize || 'N/A'}"
  end

  def trigger_compliance_webhooks
    webhook_payload = @report_data.merge({
      event: 'sla.compliance_report',
      webhook_type: 'compliance_report'
    })

    @account.webhooks.active.each do |webhook|
      next unless webhook.settings&.dig('sla_filters', 'compliance_reports')
      
      Sla::WebhookJob.perform_later(webhook.url, webhook_payload)
    end
  end
end