class DataExports::ContactSelection
  DEFAULT_COLUMNS = %w[id name email phone_number labels].freeze
  OPTION_KEYS = %w[column_names payload label scope_name].freeze
  FILTER_KEYS = %w[attribute_key attribute_model filter_operator query_operator custom_attribute_type values timezone].freeze

  attr_reader :options

  def initialize(account:, user:, options:)
    @account = account
    @user = user
    @options = options.with_indifferent_access
  end

  def validate!
    validate_shape!
    invalid_columns = columns - (Contact.column_names + ['labels'])
    raise ArgumentError, 'Unsupported export columns.' if invalid_columns.any?
    raise ArgumentError, 'The selected label is unavailable.' if options[:label].present? && !@account.labels.exists?(title: options[:label])

    contacts.limit(1).load
    self
  rescue CustomExceptions::CustomFilter::InvalidAttribute, CustomExceptions::CustomFilter::InvalidOperator,
         CustomExceptions::CustomFilter::InvalidQueryOperator, CustomExceptions::CustomFilter::InvalidValue => e
    raise ArgumentError, e.message
  end

  def columns
    options[:column_names].presence || DEFAULT_COLUMNS
  end

  def contacts
    return Contacts::FilterService.new(@account, @user, options).perform(count: false).fetch(:contacts) if options[:payload].present?

    scope = @account.contacts.resolved_contacts(use_crm_v2: @account.feature_enabled?('crm_v2'))
    options[:label].present? ? scope.tagged_with(options[:label], any: true) : scope
  end

  private

  def validate_shape!
    unknown_keys = options.keys - OPTION_KEYS
    raise ArgumentError, "Unsupported export options: #{unknown_keys.join(', ')}." if unknown_keys.any?

    validate_columns!
    %i[label scope_name].each do |key|
      raise ArgumentError, "#{key} must be a string." if options.key?(key) && !options[key].is_a?(String)
    end
    validate_filters!
  end

  def validate_columns!
    return unless options.key?(:column_names)
    return if options[:column_names].is_a?(Array) && options[:column_names].all?(String)

    raise ArgumentError, 'Export columns must be an array of column names.'
  end

  def validate_filters!
    return unless options.key?(:payload)

    return if options[:payload].is_a?(Array) && options[:payload].all? { |filter| valid_filter?(filter) }

    raise ArgumentError, 'Export filters must be an array of contact filters.'
  end

  def valid_filter?(filter)
    filter.is_a?(Hash) && (filter.keys.map(&:to_s) - FILTER_KEYS).empty? &&
      valid_filter_strings?(filter) && valid_filter_values?(filter)
  end

  def valid_filter_strings?(filter)
    return false unless filter['attribute_key'].is_a?(String) && filter['filter_operator'].is_a?(String)

    %w[query_operator attribute_model custom_attribute_type].all? { |key| filter[key].nil? || filter[key].is_a?(String) }
  end

  def valid_filter_values?(filter)
    return false unless filter['values'].is_a?(Array)

    types = string_filter?(filter) ? [String] : [String, Numeric, TrueClass, FalseClass]
    filter['values'].all? do |value|
      types.any? do |type|
        value.is_a?(type)
      end
    end
  end

  def string_filter?(filter)
    @contact_filters ||= YAML.safe_load_file(Rails.root.join('lib/filters/filter_keys.yml')).fetch('contacts')
    data_type = @contact_filters.dig(filter['attribute_key'], 'data_type')
    %w[text text_case_insensitive labels].include?(data_type) || %w[contains does_not_contain].include?(filter['filter_operator'])
  end
end
