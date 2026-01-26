class LeadRetargeting::SendFollowUpService
  def initialize(conversation_follow_up)
    @follow_up = conversation_follow_up
    @conversation = conversation_follow_up.conversation
    @sequence = conversation_follow_up.lead_follow_up_sequence
    @enrollment = conversation_follow_up.sequence_enrollment
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
      # Create event for successful step execution
      create_step_event(current_step, 'step_executed', result[:metadata] || {})
      advance_to_next_step
    else
      # Create event for failed step
      create_step_event(current_step, 'step_failed', { error_message: result[:error] })
      handle_step_failure(current_step, result[:error])
    end
  end

  private

  def execute_step(step)
    case step['type']
    when 'first_contact'
      execute_first_contact_step(step)
    when 'wait'
      execute_wait_step(step)
    when 'send_message'
      execute_message_step(step)
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
    when 'send_email'
      execute_email_step(step)
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

  # Create an event for step execution
  def create_step_event(step, event_type, additional_metadata = {})
    return unless @enrollment

    @enrollment.create_event(
      event_type: event_type,
      step_id: step['id'],
      step_index: @follow_up.current_step,
      metadata: {
        step_name: step['name'],
        step_type: step['type']
      }.merge(additional_metadata)
    )
  end

  def execute_wait_step(_step)
    { success: true }
  end

  def execute_first_contact_step(_step)
    # El first_contact ya fue ejecutado al crear la conversación
    # Este método solo confirma que se completó
    Rails.logger.info "First contact step already executed for conversation #{@conversation.id}"
    { success: true }
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

    # Enqueue async job instead of blocking
    Webhooks::SequenceExecutionJob.perform_later(
      url,
      config['method'],
      headers,
      payload
    )

    { success: true }
  end

  def execute_email_step(step)
    # Validate contact has email before proceeding
    unless @contact.email.present?
      Rails.logger.warn "Cannot send email to contact #{@contact.id}: no email address"
      return {
        success: false,
        error: "Contact has no email address",
        metadata: { contact_id: @contact.id, contact_name: @contact.name }
      }
    end

    # 1. Obtener el agent bot del inbox
    agent_bot = @inbox.agent_bot

    if agent_bot.present?
      # Si hay un bot, lanzamos el webhook (similar a AI SMS)
      idempotency_key = generate_idempotency_key(step, suffix: 'email')

      config = step['config']
      sender_email = config['sender_email'].presence || @account.support_email

      payload = build_ai_webhook_payload(
        step: step,
        agent_bot: agent_bot,
        event_type: 'lead_followup.email_request',
        message_channel: 'email',
        context: nil,
        variables: {
          sender_email: sender_email,
          subject: config['subject'],
          content: config['content']
        }
      )

      begin
        send_agent_bot_webhook(agent_bot, payload, idempotency_key)
        return { success: true }
      rescue StandardError => e
        Rails.logger.error "AI Email message failed: #{e.message}"
        return { success: false, error: "Email webhook failed: #{e.message}" }
      end
    else
      return { success: false, error: "No agent bot found for this inbox" }
    end
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

    # Update enrollment if exists
    if @enrollment
      @enrollment.update!(current_step: @follow_up.current_step)
      @enrollment.complete!(reason)
    end

    update_sequence_stats
    auto_deactivate_sequence_if_completed

    Rails.logger.info "Completed follow-up #{@follow_up.id}: #{reason}"
  end

  def cancel_follow_up(reason)
    @follow_up.cancel_job!
    @follow_up.mark_as_cancelled!(reason)

    # Update enrollment if exists
    if @enrollment
      @enrollment.update!(current_step: @follow_up.current_step)
      @enrollment.cancel!(reason)
    end

    update_sequence_stats

    Rails.logger.info "Cancelled follow-up #{@follow_up.id}: #{reason}"
  end

  def update_sequence_stats
    # Use new enrollment-based stats
    @sequence.update_stats!
  end

  def auto_deactivate_sequence_if_completed
    # Verificar si aún quedan enrollments activos en esta secuencia
    active_count = @sequence.sequence_enrollments.active.count

    # Si no quedan follow-ups activos y el copilot está activo, desactivarlo automáticamente
    if active_count.zero? && @sequence.active?
      Rails.logger.info "All follow-ups completed for copilot #{@sequence.id} (#{@sequence.name}), auto-deactivating"

      @sequence.update!(
        active: false,
        metadata: (@sequence.metadata || {}).merge(
          auto_deactivated_at: Time.current,
          auto_deactivation_reason: 'all_conversations_completed',
          final_stats: @sequence.stats
        )
      )

      Rails.logger.info "Copilot #{@sequence.id} auto-deactivated successfully"
    end
  end

  # ==================== SEND_MESSAGE STEP METHODS ====================

  def execute_message_step(step)
    config = step['config']

    if should_respect_business_hours?(step) && !within_business_hours?
      reschedule_for_business_hours
      return { success: true, rescheduled: true }
    end

    # Determinar si la ventana de mensajería está abierta
    if within_messaging_window?
      # Ventana ABIERTA (<24h) - Usar agente de IA si está habilitado
      if config.dig('ai_config', 'enabled')
        execute_ai_message_within_window(step)
      else
        { success: false, error: 'AI config not enabled for open window' }
      end
    else
      # Ventana CERRADA (>24h) - Elegir entre template o SMS
      closed_action = config['closed_window_action'] || 'send_template'

      case closed_action
      when 'send_template'
        execute_template_message(step)
      when 'send_sms'
        execute_ai_sms_message(step)
      else
        { success: false, error: "Invalid closed_window_action: #{closed_action}" }
      end
    end
  end

  def execute_ai_message_within_window(step)
    ai_config = step.dig('config', 'ai_config')

    # 1. Obtener el agent bot del inbox
    agent_bot = @inbox.agent_bot
    raise "No agent bot configured for inbox #{@inbox.id}" unless agent_bot

    # 2. Construir payload para mensaje en ventana abierta
    payload = build_ai_webhook_payload(
      step: step,
      agent_bot: agent_bot,
      event_type: 'lead_followup.ai_message_request',
      message_channel: 'whatsapp',
      context: ai_config['context'],
      variables: ai_config['variables'] || {}
    )

    # 3. Enviar webhook
    idempotency_key = generate_idempotency_key(step)

    begin
      response = send_agent_bot_webhook(agent_bot, payload, idempotency_key)

      # 4. Procesar respuesta si es síncrona (opcional)
      process_ai_webhook_response(response, step) if response

      { success: true }
    rescue StandardError => e
      Rails.logger.error "AI message (open window) failed: #{e.message}"
      handle_ai_failure(step, e)
    end
  end

  def execute_ai_sms_message(step)
    sms_config = step.dig('config', 'sms_config')

    # 1. Obtener el agent bot del inbox
    agent_bot = @inbox.agent_bot
    raise "No agent bot configured for inbox #{@inbox.id}" unless agent_bot

    # 2. Construir payload para SMS
    payload = build_ai_webhook_payload(
      step: step,
      agent_bot: agent_bot,
      event_type: 'lead_followup.ai_sms_request',
      message_channel: 'sms',
      context: sms_config['context'],
      variables: sms_config['variables'] || {}
    )

    # 3. Enviar webhook
    idempotency_key = generate_idempotency_key(step, suffix: 'sms')

    begin
      send_agent_bot_webhook(agent_bot, payload, idempotency_key)

      { success: true }
    rescue StandardError => e
      Rails.logger.error "AI SMS message failed: #{e.message}"
      handle_ai_failure(step, e)
    end
  end

  def execute_template_message(step)
    # Igual que execute_template_step actual, pero usando config['template_config']
    template_config = step.dig('config', 'template_config')
    raise 'Template config not found' unless template_config

    context = build_variable_context
    rendered_params = render_template_params(template_config['template_params'], context)

    send_whatsapp_template(
      template_name: template_config['template_name'],
      language: template_config['language'],
      params: rendered_params
    )

    { success: true }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def build_ai_webhook_payload(step:, agent_bot: nil, event_type:, message_channel:, context:, variables:)
   _agent_bot = agent_bot # Silenciar warning de rubocop si no se usa
    context_obj = build_variable_context

    # Renderizar el contexto con variables (si existe)
    rendered_context = context.present? ? @sequence.render_param_value(context, context_obj) : nil

    # Obtener información del último mensaje
    last_message = @conversation.messages.where.not(message_type: :activity).order(created_at: :desc).first
    last_message_timestamp = last_message&.created_at&.to_i

    {
      event: event_type,
      idempotency_key: generate_idempotency_key(step),
      account: @account.webhook_data,
      inbox: @inbox.webhook_data,
      conversation: @conversation.webhook_data.merge(
        # Añadir timestamp de última actividad
        last_activity_at: @conversation.last_activity_at.to_i,
        last_message_at: last_message_timestamp
      ),
      contact: @contact.push_event_data,

      # CAMPOS ESPECÍFICOS PARA FOLLOW-UP
      follow_up_data: {
        sequence_id: @sequence.id,
        sequence_name: @sequence.name,
        step_id: step['id'],
        step_name: step['name'],
        current_step: @follow_up.current_step,

        # Channel del mensaje
        message_channel: message_channel,

        # Número de teléfono del inbox (para canales de WhatsApp)
        inbox_phone_number: @inbox.channel&.phone_number,

        # Contexto OPCIONAL - puede ser nil o vacío
        context: rendered_context,

        # Variables adicionales renderizadas
        variables: render_hash_values(variables, context_obj),

        system_prompt_override: step.dig('config', 'ai_config', 'system_prompt_override') ||
                                step.dig('config', 'sms_config', 'system_prompt_override')
      }
    }
  end

  def send_agent_bot_webhook(agent_bot, payload, idempotency_key)
    AgentBots::WebhookJob.perform_now(
      agent_bot.outgoing_url,
      payload,
      :lead_followup_ai_webhook,
      idempotency_key
    )
  end

  def process_ai_webhook_response(response, step)
    # TODO: Implementar procesamiento de respuesta síncrona si es necesario
    # Por ahora, los agentes responderán de forma asíncrona vía API
  end

  def handle_ai_failure(step, error)
    fallback_action = step.dig('config', 'fallback_action') || 'skip'

    case fallback_action
    when 'send_template'
      if step.dig('config', 'template_config').present?
        Rails.logger.info 'AI failed, falling back to template'
        execute_template_message(step)
      else
        Rails.logger.warn 'AI failed but no template config for fallback'
        { success: false, error: error.message }
      end
    when 'skip'
      Rails.logger.warn "AI failed, skipping step: #{error.message}"
      { success: false, error: error.message }
    else
      { success: false, error: error.message }
    end
  end

  def generate_idempotency_key(step, suffix: nil)
    base = "#{@follow_up.id}-#{step['id']}-#{@follow_up.current_step}-#{Time.current.to_i}"
    data = suffix ? "#{base}-#{suffix}" : base
    Digest::SHA256.hexdigest(data)
  end
end
