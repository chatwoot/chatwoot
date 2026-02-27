class LeadFollowUpSequence < ApplicationRecord
  belongs_to :account
  belongs_to :inbox, optional: true
  has_many :conversation_follow_ups, dependent: :destroy
  has_many :sequence_enrollments, dependent: :destroy
  has_many :enrollment_events, dependent: :destroy

  validates :name, presence: true
  validates :source_type, presence: true, inclusion: { in: %w[existing_conversations notion_database] }
  validate :inbox_validation
  validate :inbox_must_be_messaging_channel
  validate :one_active_sequence_per_inbox
  validate :steps_structure
  validate :validate_templates_exist
  validate :validate_trigger_conditions
  validate :validate_source_config
  validate :validate_first_contact_config

  after_commit :enroll_eligible_conversations, if: :should_auto_enroll?
  after_commit :sync_notion_custom_attributes, if: :notion_database?

  scope :active, -> { where(active: true) }

  STEP_TYPES = %w[
    first_contact
    wait
    send_message
    add_label
    remove_label
    assign_agent
    assign_team
    condition
    webhook
    change_priority
    update_pipeline_status
    send_email
  ].freeze

  AVAILABLE_VARIABLES = {
    contact: %w[id name email phone_number city country_code],
    conversation: %w[id display_id status priority created_at],
    account: %w[id name],
    inbox: %w[id name],
    meta_campaign: %w[source_id source_type headline body],
    custom_attr: :dynamic
  }.freeze

  # Configuraciones disponibles para detener el copilot automáticamente
  # Estas se manejan via event-driven en LeadFollowUpListener
  STOP_CONDITIONS = {
    stop_on_contact_reply: {
      label: 'Stop when contact replies',
      description: 'Automatically stop when the contact sends a message',
      default: false,
      event_trigger: :message_created
    },
    stop_on_conversation_resolved: {
      label: 'Stop when conversation is resolved',
      description: 'Stop when the conversation status changes to resolved',
      default: false,
      event_trigger: :conversation_updated
    },
    stop_on_agent_assigned: {
      label: 'Stop when agent is assigned',
      description: 'Stop when a human agent is assigned to the conversation',
      default: false,
      event_trigger: :conversation_updated
    },
    stop_on_agent_reply: {
      label: 'Stop when agent replies',
      description: 'Stop when a human agent sends a message',
      default: false,
      event_trigger: :message_created
    }
  }.freeze

  def activate!
    update!(active: true)
  end

  def deactivate!
    update!(active: false)

    # Cancelar cada follow-up activo individualmente para que se cancelen los jobs de Sidekiq
    conversation_follow_ups.where(status: 'active').find_each do |follow_up|
      follow_up.cancel_job!
      follow_up.mark_as_cancelled!('Copilot deactivated')
    end

    Rails.logger.info "Deactivated copilot #{id} and cancelled #{conversation_follow_ups.where(status: 'cancelled').count} active follow-ups"
  end

  def step_by_id(step_id)
    steps.find { |s| s['id'] == step_id }
  end

  def enabled_steps
    steps.select { |s| s['enabled'] == true }
  end

  def matches_reactivation_filters?(conversation)
    return true if trigger_conditions.blank?

    matches_date_filter?(conversation) &&
      matches_label_filter?(conversation) &&
      matches_status_filter?(conversation) &&
      matches_pipeline_status_filter?(conversation)
  end

  def matches_date_filter?(conversation)
    filter = trigger_conditions['date_filter']
    return true unless filter&.dig('enabled')

    date_to_check = case filter['filter_type']
                    when 'conversation_created_at'
                      conversation.created_at
                    when 'last_message_at'
                      conversation.messages.maximum(:created_at)
                    when 'inactive_days'
                      conversation.last_activity_at
                    end

    return false unless date_to_check

    case filter['operator']
    when 'older_than'
      date_to_check < filter['value'].to_i.days.ago
    when 'newer_than'
      date_to_check > filter['value'].to_i.days.ago
    when 'between'
      from_date = Date.parse(filter['from_date'])
      to_date = Date.parse(filter['to_date'])
      date_to_check.to_date.between?(from_date, to_date)
    else
      false
    end
  rescue StandardError => e
    Rails.logger.error("Error evaluating date filter for sequence #{id}: #{e.message}")
    false
  end

  def matches_label_filter?(conversation)
    filter = trigger_conditions['label_filter']
    return true unless filter&.dig('enabled')
    return true if filter['labels'].blank?

    conversation_labels = conversation.cached_label_list_array
    # OR logic: conversation must have at least one of the selected labels
    filter['labels'].intersect?(conversation_labels)
  end

  def matches_status_filter?(conversation)
    filter = trigger_conditions['status_filter']
    return true unless filter&.dig('enabled')
    return true if filter['statuses'].blank?

    # Check if conversation status is in the selected statuses
    filter['statuses'].include?(conversation.status)
  end

  def matches_pipeline_status_filter?(conversation)
    filter = trigger_conditions['pipeline_status_filter']
    return true unless filter&.dig('enabled')
    return true if filter['pipeline_status_ids'].blank?

    # Check if conversation pipeline_status_id is in the selected pipeline status IDs
    filter['pipeline_status_ids'].include?(conversation.pipeline_status_id)
  end

  def render_param_value(value, context)
    return value unless value.is_a?(String)

    result = value.dup
    result.scan(/\{\{([^}]+)\}\}/).each do |match|
      variable_path = match[0].strip
      resolved_value = resolve_variable(variable_path, context)
      result.gsub!("{{#{variable_path}}}", resolved_value.to_s)
    end
    result
  end

  private

  def inbox_validation
    # Inbox is required only for existing_conversations source type
    return unless source_type == 'existing_conversations'

    errors.add(:inbox, 'is required for existing conversations') if inbox_id.blank?
  end

  def inbox_must_be_messaging_channel
    return unless inbox
    return if source_type == 'notion_database' # For notion, inbox is in first_contact_config

    supported = %w[Channel::Whatsapp Channel::TwilioSms Channel::Email]
    errors.add(:inbox, 'must be a WhatsApp, SMS, or Email inbox') unless supported.include?(inbox.channel_type)
  end

  def one_active_sequence_per_inbox
    return unless inbox_id && active

    existing = LeadFollowUpSequence.where(inbox_id: inbox_id, active: true)
                                   .where.not(id: id)
                                   .exists?

    return unless existing

    errors.add(:inbox, 'already has an active copilot. Please deactivate it before activating this one.')
  end

  def steps_structure
    return if steps.blank?

    unless steps.is_a?(Array)
      errors.add(:steps, 'must be an array')
      return
    end

    steps.each_with_index do |step, index|
      validate_step(step, index)
    end
  end

  def validate_step(step, index)
    unless step.is_a?(Hash)
      errors.add(:steps, "step at index #{index} must be a hash")
      return
    end

    errors.add(:steps, "step at index #{index} has invalid type: #{step['type']}") unless STEP_TYPES.include?(step['type'])

    errors.add(:steps, "step at index #{index} must have an id") if step['id'].blank?

    case step['type']
    when 'wait'
      validate_wait_step(step, index)
    when 'send_message'
      validate_message_step(step, index)
    when 'update_pipeline_status'
      validate_pipeline_status_step(step, index)
    when 'send_email'
      validate_email_step(step, index)
    end
  end

  def validate_email_step(step, index)
    config = step['config'] || {}
    return if config['email_inbox_id'].blank?

    email_inbox = account.inboxes.find_by(id: config['email_inbox_id'])
    unless email_inbox
      errors.add(:steps, "send_email step at index #{index} email_inbox_id references non-existent inbox")
      return
    end

    return if email_inbox.channel_type == 'Channel::Email'

    errors.add(:steps, "send_email step at index #{index} email_inbox_id must reference an Email inbox")
  end

  def validate_wait_step(step, index)
    config = step['config'] || {}

    unless config['delay_value'].present? && config['delay_value'].to_i.positive?
      errors.add(:steps, "wait step at index #{index} must have delay_value > 0")
    end

    return if %w[minutes hours days].include?(config['delay_type'])

    errors.add(:steps, "wait step at index #{index} must have delay_type: minutes, hours, or days")
  end

  def validate_pipeline_status_step(step, index)
    config = step['config'] || {}

    return if config['pipeline_status_id'].present?

    errors.add(:steps, "update_pipeline_status step at index #{index} must have pipeline_status_id")
  end

  def validate_message_step(step, index)
    config = step['config'] || {}

    # AI config: el agent_bot se obtiene automáticamente del inbox
    # Context es OPCIONAL - no validar su presencia

    # Validar configuración para ventana cerrada
    closed_action = config['closed_window_action'] || 'send_template'

    case closed_action
    when 'send_template'
      if config['template_config'].present?
        template = config['template_config']
        unless template['template_name'].present? && template['language'].present?
          errors.add(:steps, "message step at index #{index} with send_template action must have template_config")
        end
      else
        errors.add(:steps, "message step at index #{index} requires template_config when closed_window_action is send_template")
      end

      validate_step_inbox_type(config['whatsapp_inbox_id'], 'Channel::Whatsapp', "whatsapp_inbox_id at step #{index}") if config['whatsapp_inbox_id'].present?

    when 'send_sms'
      validate_step_inbox_type(config['sms_inbox_id'], %w[Channel::TwilioSms Channel::Sms], "sms_inbox_id at step #{index}") if config['sms_inbox_id'].present?

    when 'send_email'
      validate_step_inbox_type(config['email_inbox_id'], 'Channel::Email', "email_inbox_id at step #{index}") if config['email_inbox_id'].present?

    else
      errors.add(:steps, "message step at index #{index} has invalid closed_window_action: #{closed_action}")
    end
  end

  def validate_step_inbox_type(inbox_id, expected_types, field_label)
    inbox = account.inboxes.find_by(id: inbox_id)
    unless inbox
      errors.add(:steps, "#{field_label} references non-existent inbox")
      return
    end

    allowed = Array(expected_types)
    errors.add(:steps, "#{field_label} must reference a #{allowed.map { |t| t.split('::').last }.join(' or ')} inbox") unless allowed.include?(inbox.channel_type)
  end

  def validate_templates_exist
    return unless inbox&.channel
    return unless steps.is_a?(Array)
    return unless inbox.channel.respond_to?(:message_templates)

    available_templates = inbox.channel.message_templates || []

    # Validar templates en send_message steps
    message_steps = steps.select { |s| s['type'] == 'send_message' }
    message_steps.each do |step|
      config = step['config'] || {}

      # Validar template_config si closed_window_action es send_template
      if config['closed_window_action'] == 'send_template' && config['template_config'].present?
        template_config = config['template_config']
        validate_template_exists(template_config['template_name'], template_config['language'], available_templates)
      end
    end
  end

  def validate_template_exists(template_name, language, available_templates)
    return unless template_name && language

    template_exists = available_templates.any? do |t|
      t['name'] == template_name && t['language'] == language
    end

    return if template_exists

    errors.add(:steps, "Template '#{template_name}' (#{language}) not found in WhatsApp inbox")
  end

  def resolve_variable(variable_path, context)
    parts = variable_path.split('.')
    scope = parts[0]
    attribute = parts[1]

    case scope
    when 'contact'
      context[:contact]&.send(attribute)
    when 'conversation'
      context[:conversation]&.send(attribute)
    when 'account'
      context[:account]&.send(attribute)
    when 'inbox'
      context[:inbox]&.send(attribute)
    when 'meta_campaign'
      context[:meta_campaign]&.dig('metadata', attribute) ||
        context[:meta_campaign]&.send(attribute)
    when 'custom_attr'
      context[:contact]&.custom_attributes&.dig(attribute)
    else
      "[Unknown variable: #{variable_path}]"
    end
  rescue StandardError => e
    Rails.logger.error "Failed to resolve variable #{variable_path}: #{e.message}"
    "[Error: #{variable_path}]"
  end

  def validate_trigger_conditions
    return if trigger_conditions.blank?

    validate_date_filter_structure if trigger_conditions['date_filter'].present?
    validate_label_filter_structure if trigger_conditions['label_filter'].present?
    validate_status_filter_structure if trigger_conditions['status_filter'].present?
    validate_pipeline_status_filter_structure if trigger_conditions['pipeline_status_filter'].present?
    validate_enrollment_filter_structure if trigger_conditions['enrollment_filter'].present?
  end

  def validate_date_filter_structure
    filter = trigger_conditions['date_filter']
    return unless filter['enabled']

    valid_types = %w[conversation_created_at last_message_at inactive_days]
    errors.add(:trigger_conditions, "Invalid date filter type: #{filter['filter_type']}") unless valid_types.include?(filter['filter_type'])

    valid_operators = %w[older_than newer_than between]
    errors.add(:trigger_conditions, "Invalid date operator: #{filter['operator']}") unless valid_operators.include?(filter['operator'])

    if filter['operator'] == 'between'
      errors.add(:trigger_conditions, 'Date range requires from_date and to_date') unless filter['from_date'].present? && filter['to_date'].present?
    elsif filter['value'].to_i <= 0
      errors.add(:trigger_conditions, 'Date filter value must be positive')
    end
  end

  def validate_label_filter_structure
    filter = trigger_conditions['label_filter']
    return unless filter['enabled']

    return if filter['labels'].is_a?(Array) && filter['labels'].any?

    errors.add(:trigger_conditions, 'Label filter requires at least one label')
  end

  def validate_status_filter_structure
    filter = trigger_conditions['status_filter']
    return unless filter['enabled']

    valid_statuses = %w[open resolved pending snoozed]
    errors.add(:trigger_conditions, 'Status filter requires at least one status') unless filter['statuses'].is_a?(Array) && filter['statuses'].any?

    invalid_statuses = filter['statuses'] - valid_statuses
    return unless invalid_statuses.any?

    errors.add(:trigger_conditions, "Invalid statuses: #{invalid_statuses.join(', ')}")
  end

  def validate_pipeline_status_filter_structure
    filter = trigger_conditions['pipeline_status_filter']
    return unless filter['enabled']

    unless filter['pipeline_status_ids'].is_a?(Array) && filter['pipeline_status_ids'].any?
      errors.add(:trigger_conditions, 'Pipeline status filter requires at least one pipeline status')
    end

    # Validate that all pipeline_status_ids exist in the account
    valid_pipeline_status_ids = account.pipeline_statuses.pluck(:id)
    invalid_ids = filter['pipeline_status_ids'] - valid_pipeline_status_ids
    return unless invalid_ids.any?

    errors.add(:trigger_conditions, "Invalid pipeline status IDs: #{invalid_ids.join(', ')}")
  end

  def validate_enrollment_filter_structure
    filter = trigger_conditions['enrollment_filter']
    return if filter.blank?

    unless [true, false].include?(filter['include_completed'])
      errors.add(:trigger_conditions, 'Enrollment filter include_completed must be a boolean')
    end
  end

  def validate_source_config
    return unless source_type == 'notion_database'

    errors.add(:source_config, 'is required for notion_database source') if source_config.blank?
    return if source_config.blank?

    # Validate notion database ID
    if source_config['notion_database_id'].blank?
      errors.add(:source_config, 'must have a notion_database_id')
    end

    # Validate field mappings
    if source_config['field_mappings'].blank?
      errors.add(:source_config, 'must have field_mappings')
      return
    end

    # Phone number is required
    if source_config.dig('field_mappings', 'phone_number').blank?
      errors.add(:source_config, 'must have phone_number field mapping')
    end
  end

  def validate_first_contact_config
    return unless source_type == 'notion_database'

    # Find first_contact step in steps array
    first_contact_step = steps&.find { |s| s['type'] == 'first_contact' }

    if first_contact_step.blank?
      errors.add(:steps, 'must include a first_contact step for notion_database source')
      return
    end

    # Validate it's the first step
    if steps.first['type'] != 'first_contact'
      errors.add(:steps, 'first_contact step must be the first step for notion_database source')
      return
    end

    config = first_contact_step['config'] || {}

    # Validate channel
    unless %w[whatsapp sms email].include?(config['channel'])
      errors.add(:steps, 'first_contact step must have a valid channel (whatsapp, sms, or email)')
      return
    end

    # Validate inbox_id
    if config['inbox_id'].blank?
      errors.add(:steps, 'first_contact step must have inbox_id')
    end

    # Validate WhatsApp configuration
    if config['channel'] == 'whatsapp' && config['template_name'].blank?
      errors.add(:steps, 'first_contact step must have template_name when channel is whatsapp')
    end

    # Validate inbox exists and matches the configured channel type
    return if config['inbox_id'].blank?

    inbox = account.inboxes.find_by(id: config['inbox_id'])
    unless inbox
      errors.add(:steps, 'first_contact step inbox_id references non-existent inbox')
      return
    end

    expected_channel_type = case config['channel']
                            when 'whatsapp' then 'Channel::Whatsapp'
                            when 'sms'      then 'Channel::TwilioSms'
                            when 'email'    then 'Channel::Email'
                            end

    return if inbox.channel_type == expected_channel_type

    errors.add(:steps, "first_contact step inbox must be a #{config['channel'].upcase} inbox")
  end

  def should_auto_enroll?
    return false unless active?

    previously_new_record? || saved_change_to_active?
  end

  def enroll_eligible_conversations
    Rails.logger.info "Triggering auto-enrollment for sequence #{id} (#{name}) - source: #{source_type}"

    case source_type
    when 'existing_conversations'
      EnrollEligibleConversationsJob.perform_later(id)
    when 'notion_database'
      EnrollNotionDatabaseRecordsJob.perform_later(id)
    else
      Rails.logger.error "Unknown source_type: #{source_type} for sequence #{id}"
    end
  end

  # Calculate stats from sequence_enrollments
  # Calculate stats using cached counters
  def calculate_stats
    # Use counter caches to avoid COUNT queries
    total_enrolled = enrollments_count
    total_completed = completed_enrollments_count

    completion_rate = if total_enrolled.positive?
                        ((total_completed.to_f / total_enrolled) * 100).round(2)
                      else
                        0.0
                      end

    {
      total_enrolled: total_enrolled,
      total_active: active_enrollments_count,
      total_completed: total_completed,
      total_cancelled: cancelled_enrollments_count,
      total_failed: failed_enrollments_count,
      completion_rate: completion_rate
    }
  end

  # Determine if manual update is needed (usually no, if using counter_culture correctly)
  # Keeping this method signature to avoid breaking callers, but it simply returns current stats
  def update_stats!
    # With counter caches, we don't need to do expensive recalculations.
    # We might just update the stats JSON column if necessary, or better yet,
    # rely on the consumer to use the new columns + calculate_stats.
    update_column(:stats, calculate_stats)
  end

  def notion_database?
    source_type == 'notion_database'
  end

  def sync_notion_custom_attributes
    return unless source_config.is_a?(Hash)

    custom_attrs = source_config.dig('field_mappings', 'custom_attributes')
    return if custom_attrs.blank?

    custom_attrs.each_key do |attribute_key|
      # Skip internal/metadata keys
      next if attribute_key.to_s.start_with?('source_', 'attr_')

      # Find or create custom attribute definition
      CustomAttributeDefinition.find_or_create_by!(
        account: account,
        attribute_model: :contact_attribute,
        attribute_key: attribute_key.to_s
      ) do |definition|
        definition.attribute_display_name = attribute_key.to_s.titleize
        definition.attribute_display_type = :text
        definition.attribute_description = "Imported from Notion database"
      end
    end
  rescue StandardError => e
    Rails.logger.error "Failed to sync Notion custom attributes: #{e.message}"
  end
end
