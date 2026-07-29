# frozen_string_literal: true

# Validates business_rules before they are enabled. Disabled invalid rules may be saved.
class BusinessRules::LintService
  Result = Struct.new(:ok?, :errors, keyword_init: true)
  Error = Struct.new(:rule_id, :code, :message_key, :meta, keyword_init: true)

  EQUALITY_OPS = %w[equal_to not_equal_to].freeze

  def initialize(account:, rules:)
    @account = account
    @rules = Array(rules).map { |r| r.is_a?(Hash) ? r.with_indifferent_access : r }
  end

  def perform
    errors = []
    @rules.each do |rule|
      next unless ActiveModel::Type::Boolean.new.cast(rule[:enabled])

      errors.concat(lint_rule(rule))
    end
    errors.concat(lint_forbid_vs_require)
    Result.new(ok?: errors.empty?, errors: errors)
  end

  private

  def lint_rule(rule)
    type = rule[:type].to_s
    config = (rule[:config].is_a?(Hash) ? rule[:config] : {}).with_indifferent_access
    conditions = Array(rule[:conditions]).map { |c| c.is_a?(Hash) ? c.with_indifferent_access : c }
    errors = []

    errors.concat(impossible_and_errors(rule, conditions))
    errors.concat(unknown_key_errors(rule, config, conditions))
    errors.concat(empty_require_errors(rule, type, config)) if %w[require_attributes_on_status if_attribute_then_require].include?(type)
    errors.concat(missing_trigger_errors(rule, type, config, conditions)) if type == 'if_attribute_then_require'
    errors
  end

  def impossible_and_errors(rule, conditions)
    return [] if conditions.size < 2

    errors = []
    # Walk adjacent pairs joined by previous condition's query_operator == and
    conditions.each_cons(2).with_index do |(left, right), index|
      joiner = left[:query_operator].to_s.downcase
      next unless joiner == 'and'

      left_key = left[:attribute_key].to_s
      right_key = right[:attribute_key].to_s
      next if left_key.blank? || left_key != right_key
      next unless EQUALITY_OPS.include?(left[:filter_operator].to_s)
      next unless EQUALITY_OPS.include?(right[:filter_operator].to_s)

      left_vals = normalize_values(left[:values]).map { |v| v.to_s.downcase }
      right_vals = normalize_values(right[:values]).map { |v| v.to_s.downcase }
      next if left_vals.empty? || right_vals.empty?
      next if (left_vals & right_vals).any?

      errors << error(
        rule,
        'impossible_and',
        attribute_key: left_key,
        left_values: left_vals,
        right_values: right_vals,
        condition_index: index
      )
    end
    errors
  end

  def unknown_key_errors(rule, config, conditions)
    errors = []
    known_conv = known_keys_for(:conversation_attribute)
    known_contact = known_keys_for(:contact_attribute)

    Array(config[:attribute_keys]).each do |key|
      next if key.blank? || known_conv.include?(key.to_s)

      errors << error(rule, 'unknown_attribute_key', attribute_key: key, attribute_model: 'conversation')
    end
    Array(config[:contact_attribute_keys]).each do |key|
      next if key.blank? || known_contact.include?(key.to_s)

      errors << error(rule, 'unknown_attribute_key', attribute_key: key, attribute_model: 'contact')
    end
    Array(config[:require_attribute_keys]).each do |key|
      next if key.blank? || known_conv.include?(key.to_s)

      errors << error(rule, 'unknown_attribute_key', attribute_key: key, attribute_model: 'conversation')
    end
    Array(config[:require_contact_attribute_keys]).each do |key|
      next if key.blank? || known_contact.include?(key.to_s)

      errors << error(rule, 'unknown_attribute_key', attribute_key: key, attribute_model: 'contact')
    end
    when_key = config[:when_attribute].to_s
    if when_key.present?
      model = (config[:when_attribute_model].presence || 'conversation').to_s
      known = model == 'contact' ? known_contact : known_conv
      unless known.include?(when_key)
        errors << error(rule, 'unknown_attribute_key', attribute_key: when_key, attribute_model: model)
      end
    end
    reason_key = config[:reason_attribute_key].to_s
    if reason_key.present? && !known_conv.include?(reason_key)
      errors << error(rule, 'unknown_attribute_key', attribute_key: reason_key, attribute_model: 'conversation')
    end

    conditions.each do |condition|
      key = condition[:attribute_key].to_s
      next if key.blank? || standard_condition_key?(key)

      custom_type = condition[:custom_attribute_type].to_s
      if custom_type == 'contact_attribute'
        next if known_contact.include?(key)

        errors << error(rule, 'unknown_attribute_key', attribute_key: key, attribute_model: 'contact')
      elsif custom_type == 'conversation_attribute'
        next if known_conv.include?(key)

        errors << error(rule, 'unknown_attribute_key', attribute_key: key, attribute_model: 'conversation')
      else
        next if known_conv.include?(key) || known_contact.include?(key)

        errors << error(rule, 'unknown_attribute_key', attribute_key: key, attribute_model: 'conversation')
      end
    end

    Array(config[:attribute_category_keys]).each do |cat|
      next if cat.blank? || known_categories_for(:conversation_attribute).include?(cat.to_s)

      errors << error(rule, 'unknown_category', category: cat, attribute_model: 'conversation')
    end
    Array(config[:contact_attribute_category_keys]).each do |cat|
      next if cat.blank? || known_categories_for(:contact_attribute).include?(cat.to_s)

      errors << error(rule, 'unknown_category', category: cat, attribute_model: 'contact')
    end
    Array(config[:require_attribute_category_keys]).each do |cat|
      next if cat.blank? || known_categories_for(:conversation_attribute).include?(cat.to_s)

      errors << error(rule, 'unknown_category', category: cat, attribute_model: 'conversation')
    end
    Array(config[:require_contact_attribute_category_keys]).each do |cat|
      next if cat.blank? || known_categories_for(:contact_attribute).include?(cat.to_s)

      errors << error(rule, 'unknown_category', category: cat, attribute_model: 'contact')
    end

    errors
  end

  def empty_require_errors(rule, type, config)
    if type == 'require_attributes_on_status'
      keys = BusinessRules::RequiredAttributeKeys.resolve(
        account: @account,
        attribute_keys: config[:attribute_keys],
        attribute_category_keys: config[:attribute_category_keys],
        attribute_model: :conversation_attribute
      ) + BusinessRules::RequiredAttributeKeys.resolve(
        account: @account,
        attribute_keys: config[:contact_attribute_keys],
        attribute_category_keys: config[:contact_attribute_category_keys],
        attribute_model: :contact_attribute
      )
    else
      keys = BusinessRules::RequiredAttributeKeys.resolve(
        account: @account,
        attribute_keys: config[:require_attribute_keys],
        attribute_category_keys: config[:require_attribute_category_keys],
        attribute_model: :conversation_attribute
      ) + BusinessRules::RequiredAttributeKeys.resolve(
        account: @account,
        attribute_keys: config[:require_contact_attribute_keys],
        attribute_category_keys: config[:require_contact_attribute_category_keys],
        attribute_model: :contact_attribute
      )
    end

    return [] if keys.any?

    [error(rule, 'empty_require_set')]
  end

  def missing_trigger_errors(rule, _type, config, conditions)
    return [] if conditions.any? { |c| c[:attribute_key].present? }
    return [] if config[:when_attribute].to_s.present?

    [error(rule, 'missing_trigger')]
  end

  def lint_forbid_vs_require
    enabled = @rules.select { |r| ActiveModel::Type::Boolean.new.cast(r[:enabled]) }
    forbid_statuses = enabled.select { |r| r[:type].to_s == 'forbid_status_if' }.filter_map do |r|
      config = (r[:config].is_a?(Hash) ? r[:config] : {}).with_indifferent_access
      status = config[:status].to_s
      next if status.blank?

      [r, status]
    end

    errors = []
    forbid_statuses.each do |forbid_rule, status|
      enabled.each do |other|
        next if other[:id].to_s == forbid_rule[:id].to_s

        config = (other[:config].is_a?(Hash) ? other[:config] : {}).with_indifferent_access
        conflict = case other[:type].to_s
                   when 'require_attributes_on_status', 'require_assignee_on_status'
                     config[:status].to_s == status
                   when 'if_attribute_then_require'
                     (config[:on_status].presence || 'resolved').to_s == status
                   when 'require_reason_on_status'
                     Array(config[:statuses]).map(&:to_s).include?(status)
                   else
                     false
                   end
        next unless conflict

        errors << error(
          forbid_rule,
          'forbid_conflicts_require',
          status: status,
          other_rule_id: other[:id],
          other_rule_name: other[:name]
        )
      end
    end
    errors
  end

  def known_keys_for(attribute_model)
    @known_keys ||= {}
    @known_keys[attribute_model] ||= @account.custom_attribute_definitions
                                             .where(attribute_model: attribute_model)
                                             .pluck(:attribute_key)
                                             .map(&:to_s)
                                             .to_set
  end

  def known_categories_for(attribute_model)
    @known_categories ||= {}
    @known_categories[attribute_model] ||= @account.custom_attribute_definitions
                                                    .where(attribute_model: attribute_model)
                                                    .where.not(category: [nil, ''])
                                                    .distinct
                                                    .pluck(:category)
                                                    .map(&:to_s)
                                                    .to_set
  end

  def standard_condition_key?(key)
    %w[
      status assignee_id team_id inbox_id labels priority
      message_type content email private_note browser_language country_code
      referer link
    ].include?(key.to_s)
  end

  def normalize_values(raw)
    BusinessRules::ConditionValues.normalize(raw)
  end

  def error(rule, code, meta = {})
    Error.new(
      rule_id: rule[:id].to_s,
      code: code,
      message_key: "BUSINESS_RULES.LINT.#{code.upcase}",
      meta: meta
    )
  end
end
