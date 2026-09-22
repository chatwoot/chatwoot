# Typed filters share the same validation boundary.
# rubocop:disable Metrics/ModuleLength
module Copilot::V2::ResourceFilters
  private

  # Keep the allowed typed cases and their validation together.
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def filtered_scope(resource, filters)
    relation = scope(resource)
    raise ArgumentError, 'Use at most ten typed filters' unless filters.is_a?(Array) && filters.size <= 10

    filters.reduce(relation) do |current, filter|
      field, operator, value = checked_filter(filter)
      if resource == 'conversations' && field == 'labels'
        label_filter(current, operator, value)
      elsif resource == 'conversations' && %w[unattended unassigned].include?(field)
        queue_filter(current, field, operator, value)
      elsif field.is_a?(String) && field.start_with?('custom_attributes.')
        custom_filter(current, resource, field.delete_prefix('custom_attributes.'), operator, value)
      else
        scalar_filter(current, resource, field, operator, value)
      end
    end
  end

  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity

  def label_filter(relation, operator, value) # rubocop:disable Metrics/CyclomaticComplexity
    values = operator == 'in' ? value : [value]
    unless %w[eq in].include?(operator) && values.is_a?(Array) && values.size.between?(1, 100) && values.all? do |item|
      item.is_a?(String) && item.present?
    end
      raise ArgumentError, 'Labels require string equality or a nonempty string list'
    end

    relation.tagged_with(values, any: true)
  end

  def checked_filter(filter)
    raise ArgumentError, 'Filters require field, operator and value' unless filter.is_a?(Hash) && filter.keys.sort == %w[field operator value]
    raise ArgumentError, 'Unsupported filter operator' unless %w[eq in gte lte contains].include?(filter['operator'])

    filter.values_at('field', 'operator', 'value')
  end

  def queue_filter(relation, field, operator, value)
    raise ArgumentError, 'Queue predicates require boolean equality' unless operator == 'eq' && [true, false].include?(value)

    matches = field == 'unattended' ? relation.unattended : relation.unassigned
    value ? matches : relation.where.not(id: matches.select(:id))
  end

  # Keep the allowed typed cases and their validation together.
  # rubocop:disable Metrics/CyclomaticComplexity
  def scalar_filter(relation, resource, field, operator, value) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
    allowed = Copilot::V2::ResourceRegistry.fetch(resource)[:fields] - %w[custom_attributes attribute_values deadlines]
    raise ArgumentError, 'Unregistered filter field' unless allowed.include?(field)

    return relation.where(field => nil) if operator == 'eq' && value.nil? && relation.klass.columns_hash[field]&.null

    if operator == 'contains'
      raise ArgumentError, 'contains requires a registered text field and nonempty string' unless
        Copilot::V2::ResourceRegistry.searchable?(resource, field) && value.is_a?(String) && value.present? && value.size <= 1_000

      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(value)}%"
      return relation.where(relation.klass.arel_table[field].matches(pattern, '\\', false))
    end
    type = Copilot::V2::ResourceRegistry.type(field)
    raise ArgumentError, 'Range operator requires integer or timestamp' if %w[gte lte].include?(operator) && %w[integer timestamp].exclude?(type)

    values = filter_values(relation.klass, field, type, operator == 'in' ? value : [value])
    node = relation.klass.arel_table[field]
    predicate = case operator
                when 'eq' then node.eq(values.first)
                when 'in' then node.in(values)
                when 'gte' then node.gteq(values.first)
                when 'lte' then node.lteq(values.first)
                end
    relation.where(predicate)
  end

  # rubocop:enable Metrics/CyclomaticComplexity

  # Keep the allowed typed cases and their validation together.
  # rubocop:disable Metrics/CyclomaticComplexity
  def filter_values(model, field, type, values)
    raise ArgumentError, 'in requires one to 100 values' unless values.is_a?(Array) && values.size.between?(1, 100)

    values = values.map { |item| checked_value(type, item) }
    return values unless model.defined_enums.key?(field)

    mapping = model.defined_enums.fetch(field)
    raise ArgumentError, 'Invalid enum value' unless values.all? { |item| mapping.key?(item) }

    values.map { |item| mapping.fetch(item) }
  end

  # rubocop:enable Metrics/CyclomaticComplexity

  def checked_value(type, value)
    valid = case type
            when 'integer' then value.is_a?(Integer)
            when 'boolean' then [true, false].include?(value)
            when 'timestamp' then value.is_a?(String) && value.match?(/\A\d{4}-\d{2}-\d{2}T.*(?:Z|[+-]\d{2}:\d{2})\z/)
            else value.is_a?(String)
            end
    raise ArgumentError, "Invalid #{type} filter value" unless valid

    type == 'timestamp' ? Time.iso8601(value) : value
  end

  def custom_filter(relation, resource, key, operator, value)
    raise ArgumentError, 'Custom attributes support equality only' unless operator == 'eq' && %w[contacts conversations].include?(resource)

    model = resource == 'contacts' ? 'contact_attribute' : 'conversation_attribute'
    definition = @account.custom_attribute_definitions.find_by(attribute_model: model, attribute_key: key)
    raise ArgumentError, 'Unknown custom attribute' unless definition

    raise ArgumentError, 'Invalid custom attribute value' unless valid_custom_value?(definition, value)

    relation.where(Arel::Nodes::InfixOperation.new('@>', relation.klass.arel_table[:custom_attributes],
                                                   Arel::Nodes.build_quoted({ key => value }.to_json)))
  end

  # Keep the allowed typed cases and their validation together.
  # rubocop:disable Metrics/CyclomaticComplexity
  def valid_custom_value?(definition, value)
    case definition.attribute_display_type
    when 'number', 'currency', 'percent' then value.is_a?(Numeric) && value.finite?
    when 'checkbox' then [true, false].include?(value)
    when 'list' then value.is_a?(String) && definition.attribute_values.include?(value)
    when 'date' then value.is_a?(String) && Date.iso8601(value).iso8601 == value
    else value.is_a?(String)
    end
  end

  # rubocop:enable Metrics/CyclomaticComplexity

  # Keep the allowed typed cases and their validation together.
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def personal_scope(relation, resource, personal, mention_window)
    return relation if personal.nil? && mention_window.nil?
    unless resource == 'conversations' && %w[assigned_to_me mentioned_me assigned_or_mentioned participating unassigned unattended].include?(personal)
      raise ArgumentError, 'Use a registered conversation personal predicate'
    end
    raise ArgumentError, 'Mention dates require a mention predicate' if mention_window && %w[mentioned_me assigned_or_mentioned].exclude?(personal)

    mentions = personal_mentions(mention_window)
    assigned = relation.where(assignee_id: @user.id)
    mentioned = relation.where(id: mentions.select(:conversation_id))
    case personal
    when 'unassigned' then relation.unassigned
    when 'unattended' then relation.unattended
    when 'assigned_to_me' then assigned
    when 'mentioned_me' then mentioned
    when 'assigned_or_mentioned' then assigned.or(mentioned)
    when 'participating' then relation.where(id: ConversationParticipant.where(account_id: @account.id, user_id: @user.id).select(:conversation_id))
    end
  end

  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity

  def personal_mentions(mention_window)
    mentions = Mention.where(account_id: @account.id, user_id: @user.id)
    return mentions unless mention_window

    bounds = evidence_window(mention_window, Time.current)
    mentions.where(mentioned_at: Time.iso8601(bounds['since'])..Time.iso8601(bounds['until']))
  end

  def evidence_window(window, captured_at)
    return { 'since' => (captured_at - 7.days).iso8601(6), 'until' => captured_at.iso8601(6) } if window.nil?
    raise ArgumentError, 'Window requires since and until timestamps' unless window.is_a?(Hash) && window.keys.sort == %w[since until]

    since = checked_value('timestamp', window['since'])
    ending = checked_value('timestamp', window['until'])
    raise ArgumentError, 'Window must be ordered and end by capture time' unless ending.between?(since, captured_at)

    { 'since' => since.iso8601(6), 'until' => ending.iso8601(6) }
  end
end
# rubocop:enable Metrics/ModuleLength
