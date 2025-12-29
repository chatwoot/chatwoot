class LeadRetargeting::SendFollowUpService
  def initialize(conversation_follow_up)
    @follow_up = conversation_follow_up
    @conversation = conversation_follow_up.conversation
    @sequence = conversation_follow_up.lead_follow_up_sequence
    @account = @conversation.account
    @inbox = @conversation.inbox
    @contact = @conversation.contact
  end

  def execute
    return cancel_follow_up('Sequence deactivated') unless @sequence.active?

    if @sequence.settings.dig('stop_on_contact_reply') && conversation_responded_recently?
      return complete_follow_up('Contact replied')
    end

    if @sequence.settings.dig('stop_on_conversation_resolved') && @conversation.resolved?
      return complete_follow_up('Conversation resolved')
    end

    current_step = @sequence.enabled_steps[@follow_up.current_step]
    return complete_follow_up('All steps completed') unless current_step

    result = execute_step(current_step)

    if result[:success]
      advance_to_next_step
    else
      handle_step_failure(current_step, result[:error])
    end
  end

  private

  def execute_step(step)
    case step['type']
    when 'wait'
      execute_wait_step(step)
    when 'send_template'
      execute_template_step(step)
    when 'add_label'
      execute_add_label_step(step)
    when 'remove_label'
      execute_remove_label_step(step)
    when 'assign_agent'
      execute_assign_agent_step(step)
    when 'assign_team'
      execute_assign_team_step(step)
    when 'condition'
      execute_condition_step(step)
    when 'webhook'
      execute_webhook_step(step)
    when 'change_priority'
      execute_change_priority_step(step)
    when 'update_pipeline_status'
      execute_update_pipeline_status_step(step)
    else
      { success: false, error: "Unknown step type: #{step['type']}" }
    end
  rescue StandardError => e
    Rails.logger.error "Failed to execute step #{step['id']}: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    { success: false, error: e.message }
  end

  def execute_wait_step(_step)
    { success: true }
  end

  def execute_template_step(step)
    config = step['config']

    if should_respect_business_hours?(step) && !within_business_hours?
      reschedule_for_business_hours
      return { success: true, rescheduled: true }
    end

    context = build_variable_context
    rendered_params = render_template_params(config['template_params'], context)

    send_whatsapp_template(
      template_name: config['template_name'],
      language: config['language'],
      params: rendered_params
    )

    { success: true }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def execute_add_label_step(step)
    labels = step.dig('config', 'labels') || []

    # Set Current.executed_by so activity messages show "System" as the actor
    Current.executed_by = @sequence
    @conversation.add_labels(labels)

    { success: true }
  ensure
    Current.executed_by = nil
  end

  def execute_remove_label_step(step)
    labels = step.dig('config', 'labels') || []
    return { success: true } if labels.empty?

    # Set Current.executed_by so activity messages show "System" as the actor
    Current.executed_by = @sequence
    updated_labels = @conversation.label_list - labels
    @conversation.update(label_list: updated_labels)

    { success: true }
  ensure
    Current.executed_by = nil
  end

  def execute_assign_agent_step(step)
    config = step['config']

    # Set Current.executed_by so activity messages show "System" as the actor
    Current.executed_by = @sequence

    case config['assignment_type']
    when 'specific_agent'
      agent = @account.users.find(config['agent_id'])
      @conversation.update!(assignee: agent)
    when 'round_robin'
      # Obtener los IDs de agentes miembros del inbox
      allowed_agent_ids = @conversation.inbox.inbox_members.pluck(:user_id)

      AutoAssignment::AgentAssignmentService.new(
        conversation: @conversation,
        allowed_agent_ids: allowed_agent_ids
      ).perform
    when 'team'
      team = @account.teams.find(config['team_id'])
      @conversation.update!(team: team)
    end

    { success: true }
  ensure
    Current.executed_by = nil
  end

  def execute_assign_team_step(step)
    team_id = step.dig('config', 'team_id')
    team = @account.teams.find(team_id)

    # Set Current.executed_by so activity messages show "System" as the actor
    Current.executed_by = @sequence
    @conversation.update!(team: team)

    { success: true }
  ensure
    Current.executed_by = nil
  end

  def execute_condition_step(step)
    config = step['config']

    condition_met = case config['condition_type']
                    when 'contact_replied_after_last_step'
                      conversation_responded_recently?
                    when 'conversation_resolved'
                      @conversation.resolved?
                    when 'conversation_priority'
                      @conversation.priority == config['priority_value']
                    when 'has_label'
                      @conversation.labels.pluck(:title).include?(config['label_name'])
                    when 'custom_attribute'
                      evaluate_custom_attribute_condition(config)
                    else
                      false
                    end

    handle_condition_branch(condition_met ? config['if_true'] : config['if_false'])

    { success: true }
  end

  def execute_webhook_step(step)
    config = step['config']
    context = build_variable_context

    url = @sequence.render_param_value(config['url'], context)
    headers = render_hash_values(config['headers'] || {}, context)
    payload = render_hash_values(config['payload'] || {}, context)

    response = HTTParty.send(
      config['method'].downcase.to_sym,
      url,
      headers: headers,
      body: payload.to_json
    )

    raise "Webhook failed: #{response.code} - #{response.body}" unless response.success?

    { success: true }
  end

  def execute_change_priority_step(step)
    priority = step.dig('config', 'priority')

    # Set Current.executed_by so activity messages show "System" as the actor
    Current.executed_by = @sequence
    @conversation.update!(priority: priority)

    { success: true }
  ensure
    Current.executed_by = nil
  end

  def execute_update_pipeline_status_step(step)
    pipeline_status_id = step.dig('config', 'pipeline_status_id')
    pipeline_status = @account.pipeline_statuses.find(pipeline_status_id)

    # Set Current.executed_by so activity messages show "System" as the actor
    Current.executed_by = @sequence
    @conversation.update!(pipeline_status: pipeline_status)

    { success: true }
  ensure
    Current.executed_by = nil
  end

  def build_variable_context
    meta_campaign = @conversation.meta_campaign_interaction

    {
      contact: @contact,
      conversation: @conversation,
      account: @account,
      inbox: @inbox,
      meta_campaign: meta_campaign,
      custom_attr: @contact.custom_attributes
    }
  end

  def render_template_params(params, context)
    return {} if params.blank?

    rendered = {}

    params.each do |section, values|
      rendered[section] = if values.is_a?(Hash)
                            render_hash_values(values, context)
                          elsif values.is_a?(Array)
                            values.map { |v| render_hash_values(v, context) }
                          else
                            @sequence.render_param_value(values.to_s, context)
                          end
    end

    rendered
  end

  def render_hash_values(hash, context)
    hash.transform_values do |value|
      if value.is_a?(String)
        @sequence.render_param_value(value, context)
      elsif value.is_a?(Hash)
        render_hash_values(value, context)
      else
        value
      end
    end
  end

  def send_whatsapp_template(template_name:, language:, params:)
    channel = @inbox.channel

    processor = Whatsapp::TemplateProcessorService.new(
      channel: channel,
      template_params: {
        'name' => template_name,
        'language' => language,
        'processed_params' => params
      }
    )

    name, namespace, lang_code, processed_parameters = processor.call

    raise "Template '#{template_name}' not found" if name.blank?

    message_id = channel.send_template(
      @contact.phone_number[1..],
      {
        name: name,
        namespace: namespace,
        lang_code: lang_code,
        parameters: processed_parameters
      },
      nil
    )

    raise 'Failed to send template - no message_id' unless message_id.present?

    # Render template content with actual values
    rendered_content = render_template_content(name, language, params)

    @conversation.messages.create!(
      account_id: @account.id,
      inbox_id: @inbox.id,
      message_type: :template,
      content: rendered_content,
      source_id: message_id,
      status: :sent,
      content_attributes: {
        lead_follow_up_sequence_id: @sequence.id,
        template_name: name,
        step_id: @follow_up.current_step
      }
    )

    Rails.logger.info "Sent template #{name} to #{@contact.phone_number}, message_id: #{message_id}"
  end

  def render_template_content(template_name, language, params)
    # Find the template from channel's message_templates
    template = find_template(template_name, language)
    return "Template: #{template_name}" if template.blank?

    # Extract body text from template components
    body_component = template['components']&.find { |c| c['type'] == 'BODY' }
    return "Template: #{template_name}" if body_component.blank?

    template_text = body_component['text']
    return template_text if template_text.blank? || params.blank?

    # Replace variables with actual values from processed_params
    rendered_text = template_text.dup
    body_params = params['body'] || {}

    # Replace {{1}}, {{2}}, etc. with actual values
    body_params.each do |key, value|
      rendered_text.gsub!("{{#{key}}}", value.to_s)
    end

    rendered_text
  end

  def find_template(template_name, language)
    channel = @inbox.channel
    @template_cache ||= channel.message_templates.index_by { |t| "#{t['name']}:#{t['language']}" }
    @template_cache["#{template_name}:#{language}"]
  end

  def conversation_responded_recently?
    @conversation.messages
                 .incoming
                 .where('created_at > ?', @follow_up.updated_at)
                 .exists?
  end

  def within_messaging_window?
    Conversations::MessageWindowService.new(@conversation).can_reply?
  end

  def should_respect_business_hours?(step)
    step.dig('config', 'respect_business_hours') ||
      @sequence.settings.dig('respect_business_hours')
  end

  def within_business_hours?
    settings = @sequence.settings
    return true unless settings['business_hours']

    timezone = ActiveSupport::TimeZone.new(settings['business_hours']['timezone'] || 'UTC')
    now = Time.current.in_time_zone(timezone)

    return false if now.saturday? || now.sunday?

    start_hour = Time.parse(settings['business_hours']['start'])
    end_hour = Time.parse(settings['business_hours']['end'])

    current_time = now.strftime('%H:%M')
    current_time >= start_hour.strftime('%H:%M') && current_time <= end_hour.strftime('%H:%M')
  end

  def reschedule_for_business_hours
    settings = @sequence.settings
    timezone = ActiveSupport::TimeZone.new(settings['business_hours']['timezone'] || 'UTC')
    now = Time.current.in_time_zone(timezone)

    next_business_day = now
    next_business_day += 1.day while next_business_day.saturday? || next_business_day.sunday?

    start_time = Time.parse(settings['business_hours']['start'])
    next_action_at = next_business_day.change(
      hour: start_time.hour,
      min: start_time.min
    )

    @follow_up.update!(next_action_at: next_action_at)
    @follow_up.schedule_job!

    Rails.logger.info "Rescheduled follow-up #{@follow_up.id} to next business hours: #{next_action_at}"
  end

  def advance_to_next_step
    next_step_index = @follow_up.current_step + 1
    enabled_steps = @sequence.enabled_steps

    if next_step_index >= enabled_steps.size
      complete_follow_up('All steps completed')
    else
      next_step = enabled_steps[next_step_index]
      next_action_at = calculate_next_action_time(next_step)

      @follow_up.update!(
        current_step: next_step_index,
        next_action_at: next_action_at,
        metadata: (@follow_up.metadata || {}).merge(
          last_executed_step: next_step['id'],
          last_executed_at: Time.current
        )
      )
      @follow_up.schedule_job!
    end
  end

  def calculate_next_action_time(step)
    if step['type'] == 'wait'
      config = step['config']
      delay = config['delay_value'].to_i

      case config['delay_type']
      when 'minutes'
        Time.current + delay.minutes
      when 'hours'
        Time.current + delay.hours
      when 'days'
        Time.current + delay.days
      else
        Time.current + delay.hours
      end
    else
      Time.current
    end
  end

  def handle_step_failure(step, error)
    max_retries = @sequence.settings.dig('max_retries_per_step') || 2
    retry_count = @follow_up.metadata&.dig('retry_count') || 0

    if retry_count < max_retries
      retry_delay = step.dig('config', 'retry_delay_hours') || 2

      @follow_up.update!(
        next_action_at: Time.current + retry_delay.hours,
        metadata: (@follow_up.metadata || {}).merge(
          retry_count: retry_count + 1,
          last_error: error
        )
      )
      @follow_up.schedule_job!

      Rails.logger.warn "Step failed, scheduling retry #{retry_count + 1}/#{max_retries}: #{error}"
    else
      fallback_action = step.dig('config', 'fallback_action') || 'skip'

      case fallback_action
      when 'skip'
        Rails.logger.error "Step failed after #{max_retries} retries, skipping: #{error}"
        advance_to_next_step
      when 'stop_sequence'
        Rails.logger.error "Step failed, stopping sequence: #{error}"
        @follow_up.update!(
          status: 'failed',
          metadata: (@follow_up.metadata || {}).merge(
            failure_reason: error,
            failed_step_id: step['id']
          )
        )
      end
    end
  end

  def handle_condition_branch(action)
    case action
    when 'complete_sequence'
      complete_follow_up('Condition branch: complete')
    when 'continue'
      # Continue to next step
    when /^jump_to_step_(.+)$/
      target_step_id = ::Regexp.last_match(1)
      step_index = @sequence.enabled_steps.find_index { |s| s['id'] == target_step_id }

      if step_index
        @follow_up.update!(current_step: step_index - 1)
      else
        Rails.logger.error "Target step #{target_step_id} not found, continuing normally"
      end
    end
  end

  def evaluate_custom_attribute_condition(config)
    attr_key = config['attribute_key']
    operator = config['operator']
    expected_value = config['value']

    actual_value = @contact.custom_attributes&.dig(attr_key)

    case operator
    when 'equal_to'
      actual_value == expected_value
    when 'not_equal_to'
      actual_value != expected_value
    when 'contains'
      actual_value.to_s.include?(expected_value.to_s)
    when 'is_present'
      actual_value.present?
    when 'is_not_present'
      actual_value.blank?
    else
      false
    end
  end

  def complete_follow_up(reason)
    @follow_up.cancel_job!
    @follow_up.mark_as_completed!(reason)
    update_sequence_stats

    Rails.logger.info "Completed follow-up #{@follow_up.id}: #{reason}"
  end

  def cancel_follow_up(reason)
    @follow_up.cancel_job!
    @follow_up.mark_as_cancelled!(reason)
    update_sequence_stats

    Rails.logger.info "Cancelled follow-up #{@follow_up.id}: #{reason}"
  end

  def update_sequence_stats
    stats = {
      total_enrolled: @sequence.conversation_follow_ups.count,
      total_completed: @sequence.conversation_follow_ups.where(status: 'completed').count,
      total_cancelled: @sequence.conversation_follow_ups.where(status: 'cancelled').count,
      total_active: @sequence.conversation_follow_ups.where(status: 'active').count
    }

    if stats[:total_enrolled].positive?
      stats[:completion_rate] = (stats[:total_completed].to_f / stats[:total_enrolled] * 100).round(2)
    end

    @sequence.update_column(:stats, stats)
  end
end
