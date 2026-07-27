# frozen_string_literal: true

class Conversations::BusinessRulesGuard
  Result = Struct.new(:ok?, :errors, keyword_init: true)

  def initialize(conversation:, new_status: nil)
    @conversation = conversation
    @account = conversation.account
    @new_status = (new_status || conversation.status).to_s
    @previous_status = conversation.status_in_database.to_s
  end

  def perform
    rules = Array(@account.settings&.dig('business_rules')).select { |r| r['enabled'] }
    # Legacy: conversation_required_attributes still enforce on resolve
    legacy_errors = legacy_required_on_resolve
    rule_errors = rules.flat_map { |rule| evaluate_rule(rule) }
    errors = (legacy_errors + rule_errors).uniq
    Result.new(ok?: errors.empty?, errors: errors)
  end

  private

  def legacy_required_on_resolve
    return [] unless @new_status == 'resolved'
    return [] unless status_changing_to?('resolved')

    keys = Array(@account.settings&.dig('conversation_required_attributes')).map(&:to_s)
    missing_attribute_errors(keys, code: 'required_on_resolve')
  end

  def evaluate_rule(rule)
    type = rule['type'].to_s
    raw_config = rule['config']
    config = (raw_config.is_a?(Hash) ? raw_config : {}).with_indifferent_access
    case type
    when 'require_attributes_on_status'
      require_attributes_on_status(config)
    when 'if_attribute_then_require'
      if_attribute_then_require(config)
    when 'require_reason_on_status'
      require_reason_on_status(config)
    when 'forbid_status_if'
      forbid_status_if(config)
    when 'require_assignee_on_status'
      require_assignee_on_status(config)
    else
      []
    end
  end

  def require_attributes_on_status(config)
    return [] unless status_changing_to?(config[:status].to_s)

    missing_attribute_errors(Array(config[:attribute_keys]), code: 'require_attributes_on_status')
  end

  def if_attribute_then_require(config)
    target_status = config[:on_status].presence || 'resolved'
    return [] unless status_changing_to?(target_status.to_s)

    when_key = config[:when_attribute].to_s
    return [] if when_key.blank?
    return [] unless attribute_matches?(when_key, config[:when_values])

    missing_attribute_errors(Array(config[:require_attribute_keys]), code: 'if_attribute_then_require')
  end

  def require_reason_on_status(config)
    statuses = Array(config[:statuses]).map(&:to_s)
    return [] unless statuses.include?(@new_status)
    return [] unless status_changing_to?(@new_status)

    errors = []
    reason_key = config[:reason_attribute_key].to_s
    if reason_key.present? && attribute_blank?(reason_key)
      errors << { code: 'require_reason_attribute', attribute_key: reason_key }
    end

    if ActiveModel::Type::Boolean.new.cast(config[:require_private_note]) && !recent_private_note?
      # If reason CA is filled, skip note requirement
      unless reason_key.present? && !attribute_blank?(reason_key)
        errors << { code: 'require_private_note' }
      end
    end
    errors
  end

  def forbid_status_if(config)
    return [] unless status_changing_to?(config[:status].to_s)

    label = config[:label].to_s
    return [] if label.blank?
    return [] unless @conversation.label_list.map(&:downcase).include?(label.downcase)

    [{ code: 'forbid_status_if', label: label }]
  end

  def require_assignee_on_status(config)
    return [] unless status_changing_to?(config[:status].to_s)
    return [] unless ActiveModel::Type::Boolean.new.cast(config[:require_team_or_agent])

    if @conversation.assignee_id.blank? && @conversation.team_id.blank?
      [{ code: 'require_assignee_on_status' }]
    else
      []
    end
  end

  def status_changing_to?(status)
    return false if status.blank?

    @new_status == status && @previous_status != status
  end

  def attribute_matches?(key, when_values)
    value = @conversation.custom_attributes&.[](key)
    return false if attribute_value_blank?(value)

    values = Array(when_values).map(&:to_s).reject(&:blank?)
    return true if values.empty?

    Array.wrap(value).map(&:to_s).any? { |v| values.map(&:downcase).include?(v.downcase) }
  end

  def attribute_blank?(key)
    attribute_value_blank?(@conversation.custom_attributes&.[](key))
  end

  def attribute_value_blank?(value)
    value.nil? || value == '' || (value.is_a?(Array) && value.empty?)
  end

  def missing_attribute_errors(keys, code:)
    Array(keys).map(&:to_s).reject(&:blank?).filter_map do |key|
      next unless attribute_blank?(key)

      { code: code, attribute_key: key }
    end
  end

  def recent_private_note?
    @conversation.messages
                 .where(private: true, message_type: :outgoing)
                 .where('created_at >= ?', 15.minutes.ago)
                 .exists?
  end
end
