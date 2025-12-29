class LeadFollowUpSequence < ApplicationRecord
  belongs_to :account
  belongs_to :inbox
  has_many :conversation_follow_ups, dependent: :destroy

  validates :name, presence: true
  validates :inbox, presence: true
  validate :inbox_must_be_whatsapp
  validate :steps_structure
  validate :validate_templates_exist
  validate :validate_trigger_conditions

  after_commit :enroll_eligible_conversations, if: :should_auto_enroll?

  scope :active, -> { where(active: true) }

  STEP_TYPES = %w[
    wait
    send_template
    add_label
    remove_label
    assign_agent
    assign_team
    condition
    webhook
    change_priority
    update_pipeline_status
  ].freeze

  AVAILABLE_VARIABLES = {
    contact: %w[id name email phone_number city country_code],
    conversation: %w[id display_id status priority created_at],
    account: %w[id name],
    inbox: %w[id name],
    meta_campaign: %w[source_id source_type headline body],
    custom_attr: :dynamic
  }.freeze

  def activate!
    update!(active: true)
  end

  def deactivate!
    update!(active: false)
    conversation_follow_ups.where(status: 'active').update_all(status: 'cancelled')
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
    filter = trigger_conditions.dig('date_filter')
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
    filter = trigger_conditions.dig('label_filter')
    return true unless filter&.dig('enabled')
    return true if filter['labels'].blank?

    conversation_labels = conversation.cached_label_list_array
    # OR logic: conversation must have at least one of the selected labels
    (filter['labels'] & conversation_labels).any?
  end

  def matches_status_filter?(conversation)
    filter = trigger_conditions.dig('status_filter')
    return true unless filter&.dig('enabled')
    return true if filter['statuses'].blank?

    # Check if conversation status is in the selected statuses
    filter['statuses'].include?(conversation.status)
  end

  def matches_pipeline_status_filter?(conversation)
    filter = trigger_conditions.dig('pipeline_status_filter')
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

  def inbox_must_be_whatsapp
    return unless inbox

    errors.add(:inbox, 'must be a WhatsApp inbox') unless inbox.inbox_type == 'Whatsapp'
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

    unless STEP_TYPES.include?(step['type'])
      errors.add(:steps, "step at index #{index} has invalid type: #{step['type']}")
    end

    unless step['id'].present?
      errors.add(:steps, "step at index #{index} must have an id")
    end

    case step['type']
    when 'wait'
      validate_wait_step(step, index)
    when 'send_template'
      validate_template_step(step, index)
    when 'update_pipeline_status'
      validate_pipeline_status_step(step, index)
    end
  end

  def validate_wait_step(step, index)
    config = step['config'] || {}

    unless config['delay_value'].present? && config['delay_value'].to_i.positive?
      errors.add(:steps, "wait step at index #{index} must have delay_value > 0")
    end

    unless %w[minutes hours days].include?(config['delay_type'])
      errors.add(:steps, "wait step at index #{index} must have delay_type: minutes, hours, or days")
    end
  end

  def validate_template_step(step, index)
    config = step['config'] || {}

    unless config['template_name'].present?
      errors.add(:steps, "template step at index #{index} must have template_name")
    end

    unless config['language'].present?
      errors.add(:steps, "template step at index #{index} must have language")
    end
  end

  def validate_pipeline_status_step(step, index)
    config = step['config'] || {}

    unless config['pipeline_status_id'].present?
      errors.add(:steps, "update_pipeline_status step at index #{index} must have pipeline_status_id")
    end
  end

  def validate_templates_exist
    return unless inbox&.channel
    return unless steps.is_a?(Array)
    return unless inbox.channel.respond_to?(:message_templates)

    template_steps = steps.select { |s| s['type'] == 'send_template' }
    available_templates = inbox.channel.message_templates || []

    template_steps.each do |step|
      template_name = step.dig('config', 'template_name')
      language = step.dig('config', 'language')

      next unless template_name && language

      template_exists = available_templates.any? do |t|
        t['name'] == template_name && t['language'] == language
      end

      unless template_exists
        errors.add(:steps, "Template '#{template_name}' (#{language}) not found in WhatsApp inbox")
      end
    end
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
  end

  def validate_date_filter_structure
    filter = trigger_conditions['date_filter']
    return unless filter['enabled']

    valid_types = %w[conversation_created_at last_message_at inactive_days]
    unless valid_types.include?(filter['filter_type'])
      errors.add(:trigger_conditions, "Invalid date filter type: #{filter['filter_type']}")
    end

    valid_operators = %w[older_than newer_than between]
    unless valid_operators.include?(filter['operator'])
      errors.add(:trigger_conditions, "Invalid date operator: #{filter['operator']}")
    end

    if filter['operator'] == 'between'
      unless filter['from_date'].present? && filter['to_date'].present?
        errors.add(:trigger_conditions, 'Date range requires from_date and to_date')
      end
    elsif filter['value'].to_i <= 0
      errors.add(:trigger_conditions, 'Date filter value must be positive')
    end
  end

  def validate_label_filter_structure
    filter = trigger_conditions['label_filter']
    return unless filter['enabled']

    unless filter['labels'].is_a?(Array) && filter['labels'].any?
      errors.add(:trigger_conditions, 'Label filter requires at least one label')
    end
  end

  def validate_status_filter_structure
    filter = trigger_conditions['status_filter']
    return unless filter['enabled']

    valid_statuses = %w[open resolved pending snoozed]
    unless filter['statuses'].is_a?(Array) && filter['statuses'].any?
      errors.add(:trigger_conditions, 'Status filter requires at least one status')
    end

    invalid_statuses = filter['statuses'] - valid_statuses
    if invalid_statuses.any?
      errors.add(:trigger_conditions, "Invalid statuses: #{invalid_statuses.join(', ')}")
    end
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
    if invalid_ids.any?
      errors.add(:trigger_conditions, "Invalid pipeline status IDs: #{invalid_ids.join(', ')}")
    end
  end

  def should_auto_enroll?
    return false unless active?

    previously_new_record? || saved_change_to_active?
  end

  def enroll_eligible_conversations
    Rails.logger.info "Triggering auto-enrollment for sequence #{id} (#{name})"
    EnrollEligibleConversationsJob.perform_later(id)
  end
end
