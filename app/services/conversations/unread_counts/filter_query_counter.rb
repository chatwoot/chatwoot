class Conversations::UnreadCounts::FilterQueryCounter < Conversations::FilterService
  BOOLEAN_VALUES = %w[0 1 false f n no off on t true y yes].freeze
  DATABASE_CAST_ERROR_CLASS_NAMES = %w[
    PG::DatetimeFieldOverflow
    PG::InvalidDatetimeFormat
    PG::InvalidTextRepresentation
    PG::NumericValueOutOfRange
  ].freeze
  DAYS_BEFORE_FILTER_OPERATOR = 'days_before'.freeze
  MALFORMED_QUERY_ERRORS = [NoMethodError, TypeError].freeze
  NUMERIC_ATTRIBUTE_KEYS = %w[assignee_id inbox_id].freeze
  TEXT_DATA_TYPES = %w[labels link text text_case_insensitive].freeze
  TEXT_FILTER_OPERATORS = %w[contains does_not_contain].freeze
  TYPED_DATA_TYPES = %w[boolean date number numeric].freeze
  VALID_QUERY_OPERATORS = %w[AND OR].freeze
  VALIDATION_DATA_TYPES = (TEXT_DATA_TYPES + TYPED_DATA_TYPES).freeze
  VALUELESS_FILTER_OPERATORS = %w[is_present is_not_present].freeze

  def initialize(account:, user:, query:)
    super(query.with_indifferent_access, user, account)
  end

  def perform
    return unless valid_query?
    return unless valid_typed_values?

    validate_query_operator
    query_builder(@filters['conversations']).count
  rescue *MALFORMED_QUERY_ERRORS
    nil
  rescue ActiveRecord::StatementInvalid => e
    raise unless database_cast_error?(e)

    nil
  end

  def base_relation
    Conversations::PermissionFilterService.new(unread_conversations, @user, @account).perform
  end

  private

  def valid_query?
    @params[:payload].is_a?(Array) && valid_query_operator_positions?
  end

  def database_cast_error?(error)
    DATABASE_CAST_ERROR_CLASS_NAMES.include?(error.cause&.class&.name)
  end

  def valid_query_operator_positions?
    @params[:payload].each_with_index.all? do |query_hash, index|
      query_operator_position_valid?(query_hash[:query_operator], last_query?(index))
    end
  end

  def query_operator_position_valid?(query_operator, last_query)
    return query_operator.blank? if last_query

    VALID_QUERY_OPERATORS.include?(query_operator.to_s.upcase)
  end

  def last_query?(index)
    index == @params[:payload].length - 1
  end

  def valid_typed_values?
    @params[:payload].all? do |query_hash|
      next true if VALUELESS_FILTER_OPERATORS.include?(query_hash[:filter_operator])

      data_type = validation_data_type(query_hash)
      next true if data_type.blank?
      next false if text_filter_operator?(query_hash) && TYPED_DATA_TYPES.include?(data_type)

      valid_typed_values_for?(query_hash[:values], data_type, query_hash[:filter_operator])
    end
  end

  def validation_data_type(query_hash)
    attribute_key = query_hash[:attribute_key]
    data_type = filter_data_type(query_hash)

    return nil if text_search_on_display_id?(query_hash)
    return 'number' if NUMERIC_ATTRIBUTE_KEYS.include?(attribute_key)
    return data_type if VALIDATION_DATA_TYPES.include?(data_type)

    nil
  end

  def filter_data_type(query_hash)
    attribute_key = query_hash[:attribute_key]
    data_type = @filters.dig('conversations', attribute_key, 'data_type')
    return data_type.to_s.downcase if data_type.present?

    custom_attribute_data_type(query_hash)
  end

  def custom_attribute_data_type(query_hash)
    custom_attribute_type = query_hash[:custom_attribute_type].presence || self.class::ATTRIBUTE_MODEL
    custom_attribute = @account.custom_attribute_definitions.where(
      attribute_model: custom_attribute_type
    ).find_by(attribute_key: query_hash[:attribute_key])

    self.class::ATTRIBUTE_TYPES[custom_attribute&.attribute_display_type].to_s
  end

  def valid_typed_values_for?(values, data_type, filter_operator)
    Array.wrap(values).all? do |value|
      valid_typed_value?(value, data_type, filter_operator)
    end
  end

  def text_filter_operator?(query_hash)
    TEXT_FILTER_OPERATORS.include?(query_hash[:filter_operator])
  end

  def valid_typed_value?(value, data_type, filter_operator)
    case data_type
    when 'boolean'
      BOOLEAN_VALUES.include?(value.to_s.downcase)
    when 'date'
      return Integer(value.to_s, exception: false).present? if filter_operator == DAYS_BEFORE_FILTER_OPERATOR

      Date.iso8601(value.to_s).present?
    when 'numeric'
      BigDecimal(value.to_s, exception: false).present?
    when *TEXT_DATA_TYPES
      value.is_a?(String)
    else
      Integer(value.to_s, exception: false).present?
    end
  rescue ArgumentError
    false
  end

  def unread_conversations
    @account.conversations
            .joins(:messages)
            .merge(Message.incoming.reorder(nil))
            .where(messages: { account_id: @account.id })
            .where(unread_since_last_seen_condition)
            .distinct
  end

  def unread_since_last_seen_condition
    conversations = Conversation.arel_table
    messages = Message.arel_table

    conversations[:agent_last_seen_at].eq(nil).or(messages[:created_at].gt(conversations[:agent_last_seen_at]))
  end
end
