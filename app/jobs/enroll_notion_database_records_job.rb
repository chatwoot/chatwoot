class EnrollNotionDatabaseRecordsJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 100

  def perform(sequence_id)
    sequence = LeadFollowUpSequence.find_by(id: sequence_id)
    return unless sequence&.active? && sequence.source_type == 'notion_database'

    first_step = sequence.enabled_steps.first
    unless first_step
      Rails.logger.warn "Sequence #{sequence.id} has no enabled steps, skipping enrollment"
      return
    end

    Rails.logger.info "Enrolling Notion database records for sequence #{sequence.id} (#{sequence.name})"

    enrolled_count = 0
    skipped_count = 0
    start_time = Time.current

    # Fetch records from Notion
    notion_service = Notion::DatabasesService.new(sequence.account)
    database_id = sequence.source_config['notion_database_id']

    begin
      filters = build_notion_filters(sequence.source_config)
      Rails.logger.info "Applying Notion filters: #{filters.inspect}"
      records = notion_service.query_database(database_id, filters.merge(limit: BATCH_SIZE))
      Rails.logger.info "Found #{records.count} records in Notion database #{database_id} with filters applied"
    rescue CustomExceptions::Notion::ApiError => e
      Rails.logger.error "Failed to fetch Notion records: #{e.message}"
      return
    end

    records.each do |record|
      begin
        record_id = record[:id]
        Rails.logger.info "Processing Notion record #{record_id}"
        Rails.logger.debug "Record structure: #{record.keys.inspect}"

        # Create or find contact
        contact = find_or_create_contact(sequence, record)
        unless contact
          Rails.logger.warn "Skipping record #{record_id}: Could not create/find contact"
          skipped_count += 1
          next
        end

        Rails.logger.info "Contact created/found: #{contact.id}"

        # Create or find conversation with first contact
        conversation = create_conversation_with_first_contact(sequence, contact, record)
        unless conversation
          Rails.logger.warn "Skipping record #{record_id}: Could not create conversation"
          skipped_count += 1
          next
        end

        Rails.logger.info "Conversation created: #{conversation.id}"

        # Enroll conversation in sequence
        enroll_conversation(conversation, sequence, first_step, record)
        enrolled_count += 1
        Rails.logger.info "Successfully enrolled record #{record_id}"
      rescue StandardError => e
        Rails.logger.error "Failed to enroll Notion record #{record_id}: #{e.message}"
        Rails.logger.error "Backtrace: #{e.backtrace.first(5).join("\n")}" if e.backtrace
        skipped_count += 1
      end
    end

    duration = Time.current - start_time
    Rails.logger.info "Notion enrollment complete for sequence #{sequence.id} in #{duration.round(2)}s: " \
                      "Enrolled: #{enrolled_count}, Skipped: #{skipped_count}"
  end

  private

  def find_or_create_contact(sequence, record)
    mappings = sequence.source_config['field_mappings']
    Rails.logger.info "Field mappings: #{mappings.inspect}"

    phone_number = extract_field_value(record, mappings['phone_number'])
    Rails.logger.info "Extracted phone number: #{phone_number.inspect}"

    unless phone_number
      Rails.logger.warn "No phone number found in record"
      return nil
    end

    # Clean and validate phone number
    cleaned_phone = clean_phone_number(phone_number)
    Rails.logger.info "Cleaned phone number: #{cleaned_phone.inspect}"

    unless cleaned_phone
      Rails.logger.warn "Phone number cleaning failed"
      return nil
    end

    # Get inbox for contact creation
    inbox = get_inbox_for_sequence(sequence)
    Rails.logger.info "Inbox for sequence: #{inbox&.id}"

    unless inbox
      Rails.logger.warn "No inbox found for sequence"
      return nil
    end

    contact_name = extract_field_value(record, mappings['name']) || 'Unknown'
    contact_email = extract_field_value(record, mappings['email'])
    custom_attrs = extract_custom_attributes(record, mappings)

    Rails.logger.info "Contact attributes - name: #{contact_name}, phone: #{cleaned_phone}, email: #{contact_email}"

    # Find existing contact or create new one
    existing_contact = Contact.find_by(
      account: sequence.account,
      phone_number: cleaned_phone
    )

    if existing_contact
      Rails.logger.info "Found existing contact: #{existing_contact.id}"

      # Update contact with new data from Notion
      updates = {}
      updates[:email] = contact_email if contact_email.present?
      updates[:name] = contact_name if contact_name.present? && existing_contact.name == 'Unknown'

      updates[:source_type] = 'notion_import'

      # Merge custom attributes
      merged_attrs = (existing_contact.custom_attributes || {}).merge(custom_attrs).merge(
        source_metadata: {
          notion_database_id: sequence.source_config['notion_database_id'],
          notion_record_id: record[:id],
          imported_at: Time.current.iso8601,
          sequence_id: sequence.id
        }
      )
      updates[:custom_attributes] = merged_attrs

      if updates.any?
        existing_contact.update!(updates)
        Rails.logger.info "Updated contact #{existing_contact.id} with: #{updates.keys.join(', ')}"
      end

      return existing_contact
    end

    Rails.logger.info "Creating new contact with phone: #{cleaned_phone}"

    # Generate source_id based on inbox channel type
    source_id = generate_source_id_for_inbox(cleaned_phone, inbox, email: contact_email)
    Rails.logger.info "Using source_id: #{source_id} for channel type: #{inbox.channel_type}"

    # Create new contact and contact inbox
    contact_attributes = {
      name: contact_name,
      phone_number: cleaned_phone,
      contact_type: 'lead',
      source_type: 'notion_import',
      custom_attributes: custom_attrs.merge(
        source_metadata: {
          notion_database_id: sequence.source_config['notion_database_id'],
          notion_record_id: record[:id],
          imported_at: Time.current.iso8601,
          sequence_id: sequence.id
        }
      )
    }

    # Add email if provided
    contact_attributes[:email] = contact_email if contact_email.present?

    contact_inbox = ContactInboxWithContactBuilder.new(
      source_id: source_id,
      inbox: inbox,
      contact_attributes: contact_attributes
    ).perform

    unless contact_inbox
      Rails.logger.error "ContactInboxWithContactBuilder returned nil for source_id: #{source_id}"
      return nil
    end

    Rails.logger.info "ContactInbox created: #{contact_inbox.id}, contact_id: #{contact_inbox.contact_id}"

    # Reload to ensure associations are loaded
    contact_inbox.reload
    contact = contact_inbox.contact
    unless contact
      Rails.logger.error "ContactInbox #{contact_inbox.id} has no associated contact using default scope"
      # Try to find the contact directly without scopes (including soft-deleted)
      contact = Contact.unscoped.find_by(id: contact_inbox.contact_id)
      if contact
        if contact.discarded?
          Rails.logger.warn "Contact #{contact.id} exists but is soft-deleted (discarded_at: #{contact.discarded_at})"
          # Restore the contact
          contact.undiscard
          Rails.logger.info "Contact #{contact.id} restored successfully"
        else
          Rails.logger.info "Found contact #{contact.id} using unscoped query"
        end
      else
        Rails.logger.error "Contact #{contact_inbox.contact_id} not found even with unscoped query"
        return nil
      end
    end

    Rails.logger.info "Contact created successfully: #{contact.id}"
    contact
  rescue StandardError => e
    Rails.logger.error "Failed to create contact: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(10).join("\n")}" if e.backtrace
    nil
  end

  def create_conversation_with_first_contact(sequence, contact, record)
    inbox = get_inbox_for_sequence(sequence)
    return nil unless inbox

    # Check if conversation already exists
    contact_inbox = contact.contact_inboxes.find_by(inbox: inbox)
    unless contact_inbox
      # Generate source_id based on channel type
      source_id = generate_source_id_for_inbox(contact.phone_number, inbox, email: contact.email)

      contact_inbox = ContactInbox.create!(
        contact: contact,
        inbox: inbox,
        source_id: source_id
      )
    end

    existing_conversation = contact_inbox.conversations.last
    if existing_conversation
      Rails.logger.info "Using existing conversation #{existing_conversation.id} for contact #{contact.id}"

      # Solo enviamos el primer contacto si no tiene una secuencia activa actualmente
      # Si está completada, revisamos si se permite el re-enrollment
      follow_up = existing_conversation.conversation_follow_up
      include_completed = sequence.trigger_conditions.dig('enrollment_filter', 'include_completed')

      should_send = if follow_up&.status == 'active'
                      false
                    elsif follow_up&.status == 'completed'
                      include_completed
                    else
                      true # nil, cancelled, failed, etc.
                    end

      if should_send
        send_first_contact_message(sequence, existing_conversation, contact, record)
      end

      return existing_conversation
    end

    # Create new conversation
    conversation = ConversationBuilder.new(
      params: {
        contact_id: contact.id,
        inbox_id: inbox.id,
        source_type: :notion_lead,
        source_metadata: {
          notion_database_id: sequence.source_config['notion_database_id'],
          notion_record_id: record[:id],
          sequence_id: sequence.id,
          created_at: Time.current.iso8601
        }
      },
      contact_inbox: contact_inbox
    ).perform

    # Send first contact message
    send_first_contact_message(sequence, conversation, contact, record)

    conversation
  end

  def send_first_contact_message(sequence, conversation, contact, record)
    first_step = sequence.steps.find { |s| s['type'] == 'first_contact' }
    return unless first_step

    config = first_step['config']

    case config['channel']
    when 'whatsapp'
      send_whatsapp_template(sequence, conversation, contact, record, config)
    when 'sms'
      send_ai_sms_first_contact(sequence, conversation, config, record)
    when 'email'
      send_email_first_contact(sequence, conversation, contact, config, record)
    else
      Rails.logger.error "Unknown first contact channel: #{config['channel']}"
    end
  end

  def send_whatsapp_template(sequence, conversation, contact, record, config)
    template_name = config['template_name']
    template_params = config['template_params'] || {}

    # Render template parameters with variables
    rendered_params = render_template_params(template_params, contact, record, sequence)

    # Get channel and process template
    channel = conversation.inbox.channel
    
    processor = Whatsapp::TemplateProcessorService.new(
      channel: channel,
      template_params: {
        'name' => template_name,
        'language' => config['language'] || config['template_language'] || 'es',
        'processed_params' => rendered_params
      }
    )

    name, namespace, lang_code, _processed_parameters = processor.call

    raise "Template '#{template_name}' not found" if name.blank?

    # Render template content with actual values
    rendered_content = render_template_content(conversation, name, lang_code, rendered_params)

    # Create message record first with status sent
    # This allows the provider service to record any external errors on this message object
    conversation.messages.create!(
      account_id: sequence.account.id,
      inbox_id: conversation.inbox.id,
      message_type: :template,
      content: rendered_content,
      status: :sent,
      content_attributes: {
        template_name: name,
        notion_record_id: record[:id]
      },
      'additional_attributes' => {
        'template_params' => {
          'name' => name.to_s,
          'namespace' => namespace.to_s,
          'language' => lang_code.to_s,
          'processed_params' => rendered_params
        }
      }
    )

    Rails.logger.info "Queued WhatsApp template '#{name}' for conversation #{conversation.id} via SendReplyJob"
  rescue StandardError => e
    error_message = if e.respond_to?(:record) && e.record.respond_to?(:errors)
                      "#{e.message} - Errors: #{e.record.errors.full_messages.join(', ')}"
                    else
                      e.message
                    end

    # Log detailed error information
    error_details = {
      error_class: e.class.name,
      error_message: error_message,
      contact_phone: contact.phone_number,
      template_name: template_name,
      conversation_id: conversation.id,
      notion_record_id: record[:id]
    }

    Rails.logger.error "Failed to send WhatsApp template: #{error_details.to_json}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(10).join("\n")}" if e.backtrace

    # Create a failed message record for tracking
    create_failed_template_message(sequence, conversation, error_message, record, template_name)
  end
  def render_template_content(conversation, template_name, language, params)
    # Find the template from channel's message_templates
    template = find_template(conversation.inbox.channel, template_name, language)
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

  def find_template(channel, template_name, language)
    @template_cache ||= {}
    cache_key = "#{channel.id}:#{template_name}:#{language}"
    
    return @template_cache[cache_key] if @template_cache.key?(cache_key)

    template = channel.message_templates&.find { |t| t['name'] == template_name && t['language'] == language }
    @template_cache[cache_key] = template
  end

  def create_failed_template_message(sequence, conversation, error_message, record, template_name = nil)
    # Create an activity message to track the failed send
    conversation.messages.create!(
      account_id: sequence.account.id,
      inbox_id: conversation.inbox.id,
      message_type: :activity,
      content: "Failed to send WhatsApp template: #{error_message}",
      content_attributes: {
        error: error_message,
        template_name: template_name,
        notion_record_id: record[:id],
        failed_at: Time.current.iso8601
      }
    )
    
    Rails.logger.warn "Created failed message record for conversation #{conversation.id}"
  rescue StandardError => e
    Rails.logger.error "Failed to create failed message record: #{e.message}"
  end

  def enroll_conversation(conversation, sequence, _first_step, record)
    # Check if conversation is already actively enrolled
    active_follow_up = conversation.conversation_follow_up
    if active_follow_up&.status == 'active'
      Rails.logger.info "Conversation #{conversation.id} already has active enrollment, skipping"
      return
    end

    # Check for existing completed enrollment and re-enrollment settings
    existing_enrollment = conversation.sequence_enrollments
                                     .where(lead_follow_up_sequence: sequence)
                                     .order(enrolled_at: :desc)
                                     .first

    if existing_enrollment&.status == 'completed'
      include_completed = sequence.trigger_conditions.dig('enrollment_filter', 'include_completed')
      unless include_completed
        Rails.logger.info "Skipping re-enrollment for conversation #{conversation.id}: include_completed is false"
        return
      end
    end

    # Calculate re-enrollment count
    re_enrollment_count = conversation.sequence_enrollments
                                     .where(lead_follow_up_sequence: sequence)
                                     .count

    # Para Notion, el paso first_contact (índice 0) ya se ejecutó al crear la conversación
    # Entonces empezamos desde el paso 1 (o completamos si solo hay 1 paso)
    enabled_steps = sequence.enabled_steps
    reference_date = extract_reference_date(sequence, record)

    # Create new enrollment
    enrollment = SequenceEnrollment.create!(
      conversation: conversation,
      lead_follow_up_sequence: sequence,
      enrolled_at: Time.current,
      status: 'active',
      current_step: 1, # Empezar desde el paso 1 (first_contact ya se ejecutó)
      metadata: {
        enrolled_via: 'notion_database',
        notion_record_id: record[:id],
        notion_database_id: sequence.source_config['notion_database_id'],
        reference_date: reference_date,
        re_enrollment_count: re_enrollment_count
      }
    )

    # Create enrollment event
    enrollment.create_event(
      event_type: 'enrolled',
      step_id: nil,
      step_index: nil,
      metadata: {
        source: 'notion_database',
        notion_database_id: sequence.source_config['notion_database_id'],
        notion_record_id: record[:id],
        re_enrollment: re_enrollment_count.positive?
      }
    )

    # Create event for first_contact step that was already executed
    first_contact_step = enabled_steps.first
    enrollment.create_event(
      event_type: 'step_executed',
      step_id: first_contact_step['id'],
      step_index: 0,
      metadata: {
        step_name: first_contact_step['name'],
        step_type: 'first_contact',
        channel: first_contact_step.dig('config', 'channel'),
        auto_executed: true
      }
    )

    if enabled_steps.length == 1 && enabled_steps.first['type'] == 'first_contact'
      # Solo tiene el paso first_contact, marcar enrollment como completado inmediatamente
      enrollment.complete!('All steps completed after first_contact')
      sequence.update_stats!
      Rails.logger.info "Marked enrollment #{enrollment.id} as completed (only first_contact step)"
    else
      # Tiene más pasos después de first_contact, crear ConversationFollowUp para tracking
      next_step = enabled_steps[1] # El segundo paso (índice 1)
      next_action_at = calculate_wait_time_from_date(reference_date, next_step)

      follow_up = ConversationFollowUp.find_or_initialize_by(conversation: conversation)
      follow_up.assign_attributes(
        lead_follow_up_sequence: sequence,
        sequence_enrollment: enrollment,
        current_step: 1, # Empezar desde el segundo paso (índice 1)
        next_action_at: next_action_at,
        status: 'active',
        completed_at: nil,
        processing_started_at: nil,
        metadata: (follow_up.metadata || {}).merge({
          enrolled_at: Time.current,
          enrollment_id: enrollment.id
        })
      )
      follow_up.save!
      follow_up.schedule_job!
      Rails.logger.info "Created enrollment #{enrollment.id} and scheduled job for conversation #{conversation.id}"
    end
  end

  def extract_reference_date(sequence, record)
    date_field = sequence.source_config.dig('field_mappings', 'reference_date')
    return Time.current unless date_field

    date_value = extract_field_value(record, date_field)
    date_value.present? ? Time.parse(date_value) : Time.current
  rescue StandardError => e
    Rails.logger.error "Failed to parse reference date: #{e.message}"
    Time.current
  end

  def calculate_wait_time_from_date(reference_date, step)
    return Time.current unless step['type'] == 'wait'

    config = step['config']
    delay = config['delay_value'].to_i

    calculated_time = case config['delay_type']
                      when 'minutes' then reference_date + delay.minutes
                      when 'hours' then reference_date + delay.hours
                      when 'days' then reference_date + delay.days
                      else reference_date + delay.hours
                      end

    # If calculated time is in the past, execute immediately
    [calculated_time, Time.current].max
  end

  def extract_field_value(record, field_name)
    return nil if field_name.blank? || !record[:properties]

    property = record[:properties][field_name]
    return nil unless property

    case property['type']
    when 'title'
      property['title']&.first&.dig('plain_text')
    when 'rich_text'
      property['rich_text']&.first&.dig('plain_text')
    when 'phone_number'
      property['phone_number']
    when 'email'
      property['email']
    when 'date'
      property['date']&.dig('start')
    when 'select'
      property['select']&.dig('name')
    when 'number'
      property['number']&.to_s
    else
      nil
    end
  end

  def extract_custom_attributes(record, mappings)
    custom_attrs = mappings['custom_attributes'] || {}
    result = {}

    custom_attrs.each do |key, notion_field|
      value = extract_field_value(record, notion_field)
      result[key.to_s] = value if value.present?
    end

    result
  end

  def clean_phone_number(phone)
    # Remove all non-digit characters
    digits = phone.to_s.gsub(/\D/, '')
    return nil if digits.empty?

    # Special handling for Mexico and 10-digit numbers
    # If 10 digits, add +521
    # If more than 10 digits, just add + if it's not there
    if digits.length == 10
      cleaned = "+521#{digits}"
    else
      cleaned = "+#{digits}"
    end
    
    cleaned
  end

  def get_inbox_for_sequence(sequence)
    first_step = sequence.steps.find { |s| s['type'] == 'first_contact' }
    return nil unless first_step

    inbox_id = first_step.dig('config', 'inbox_id')
    sequence.account.inboxes.find_by(id: inbox_id)
  end

  def generate_source_id_for_inbox(phone_number, inbox, email: nil)
    case inbox.channel_type
    when 'Channel::Whatsapp'
      phone_number.delete('+')
    when 'Channel::TwilioSms'
      phone_number
    when 'Channel::Email'
      email || phone_number
    else
      phone_number
    end
  end

  def render_template_params(template_params, contact, record, sequence)
    return template_params unless template_params.is_a?(Hash)

    rendered = {}

    template_params.each do |key, value|
      if value.is_a?(Hash)
        rendered[key] = render_template_params(value, contact, record, sequence)
      elsif value.is_a?(String)
        rendered[key] = render_param_value(value, contact, record, sequence)
      else
        rendered[key] = value
      end
    end

    rendered
  end

  def render_param_value(value, contact, record, sequence)
    return value unless value.is_a?(String)

    result = value.dup

    # Replace contact variables
    result.gsub!('{{contact.name}}', contact.name.to_s)
    result.gsub!('{{contact.phone_number}}', contact.phone_number.to_s)
    result.gsub!('{{contact.email}}', contact.email.to_s)

    # Replace Notion field variables
    result.scan(/\{\{notion\.([^}]+)\}\}/).each do |match|
      field_name = match[0]
      field_value = extract_field_value(record, field_name)
      result.gsub!("{{notion.#{field_name}}}", field_value.to_s)
    end

    result
  end

  def send_ai_first_contact(sequence, conversation, config, record)
    agent_bot = conversation.inbox.agent_bot
    raise "No agent bot configured for inbox #{conversation.inbox.id}" unless agent_bot

    # Construir contexto con variables de Notion
    context = build_context_with_notion_variables(config['sms_context'] || '', record, sequence)

    payload = {
      event: 'lead_followup.first_contact_request',
      conversation_id: conversation.id,
      agent_bot_id: agent_bot.id,
      channel: 'whatsapp',
      context: context,
      notion_data: extract_notion_data(record, sequence)
    }

    # Enviar webhook al agent bot
    webhook_url = agent_bot.outgoing_url
    HTTParty.post(webhook_url, {
      body: payload.to_json,
      headers: { 'Content-Type' => 'application/json' },
      timeout: 30
    })

    Rails.logger.info "Sent AI first contact request for conversation #{conversation.id}"
  rescue StandardError => e
    Rails.logger.error "Failed to send AI first contact: #{e.message}"
    raise
  end

  def send_ai_sms_first_contact(sequence, conversation, config, record)
    agent_bot = conversation.inbox.agent_bot
    raise "No agent bot configured for inbox #{conversation.inbox.id}" unless agent_bot

    context = build_context_with_notion_variables(config['sms_context'] || '', record, sequence)

    payload = {
      event: 'lead_followup.first_contact_request',
      conversation_id: conversation.id,
      agent_bot_id: agent_bot.id,
      channel: 'sms',
      context: context,
      notion_data: extract_notion_data(record, sequence)
    }

    webhook_url = agent_bot.outgoing_url
    HTTParty.post(webhook_url, {
      body: payload.to_json,
      headers: { 'Content-Type' => 'application/json' },
      timeout: 30
    })

    Rails.logger.info "Sent SMS first contact request for conversation #{conversation.id}"
  rescue StandardError => e
    Rails.logger.error "Failed to send SMS first contact: #{e.message}"
    raise
  end

  def send_email_first_contact(sequence, conversation, contact, config, record)
    inbox = sequence.account.inboxes.find_by(id: config['inbox_id'])
    raise "Email inbox #{config['inbox_id']} not found" unless inbox

    agent_bot = inbox.agent_bot
    raise "No agent bot configured for email inbox #{inbox.id}" unless agent_bot

    context = build_context_with_notion_variables(config['email_context'] || '', record, sequence)
    sender_email = config['sender_email'].presence || sequence.account.support_email

    payload = {
      event: 'lead_followup.first_contact_request',
      conversation_id: conversation.id,
      agent_bot_id: agent_bot.id,
      channel: 'email',
      context: context,
      variables: {
        to_email: contact.email,
        sender_email: sender_email,
        subject: config['subject'],
        content: config['content']
      },
      notion_data: extract_notion_data(record, sequence)
    }

    HTTParty.post(agent_bot.outgoing_url, {
      body: payload.to_json,
      headers: { 'Content-Type' => 'application/json' },
      timeout: 30
    })

    Rails.logger.info "Sent email first contact request for conversation #{conversation.id}"
  rescue StandardError => e
    Rails.logger.error "Failed to send email first contact: #{e.message}"
    raise
  end

  def build_context_with_notion_variables(context, record, sequence)
    result = context.dup

    # Reemplazar variables de Notion {{notion.campo}}
    result.scan(/\{\{notion\.([^}]+)\}\}/).each do |match|
      field_name = match[0]
      field_value = extract_field_value(record, field_name)
      result.gsub!("{{notion.#{field_name}}}", field_value.to_s)
    end

    result
  end

  def extract_notion_data(record, sequence)
    mappings = sequence.source_config['field_mappings']

    {
      record_id: record[:id],
      database_id: sequence.source_config['notion_database_id'],
      fields: {
        name: extract_field_value(record, mappings['name']),
        phone: extract_field_value(record, mappings['phone_number']),
        reference_date: extract_field_value(record, mappings['reference_date']),
        custom: extract_custom_attributes(record, mappings)
      }
    }
  end

  def within_messaging_window?(conversation)
    last_message = conversation.messages.where(message_type: :incoming).last
    return true unless last_message

    # Ventana de 24 horas
    last_message.created_at > 24.hours.ago
  end

  def build_notion_filters(source_config)
    filters = {}

    if source_config['notion_filters'].present?
      # Convert date filters from string keys to symbol keys
      if source_config['notion_filters']['date_filters'].present?
        filters[:date_filters] = source_config['notion_filters']['date_filters'].map do |df|
          {
            field_name: df['field_name'],
            operator: df['operator'],
            days: df['days']&.to_i,
            from_date: df['from_date'],
            to_date: df['to_date']
          }.compact
        end
      end

      # Convert select filters from string keys to symbol keys
      if source_config['notion_filters']['select_filters'].present?
        filters[:select_filters] = source_config['notion_filters']['select_filters'].map do |sf|
          {
            field_name: sf['field_name'],
            value: sf['value']
          }.compact
        end
      end

      # Convert checkbox filters from string keys to symbol keys
      if source_config['notion_filters']['checkbox_filters'].present?
        filters[:checkbox_filters] = source_config['notion_filters']['checkbox_filters'].map do |cf|
          {
            field_name: cf['field_name'],
            value: cf['value']
          }.compact
        end
      end
    end

    filters
  end
end
