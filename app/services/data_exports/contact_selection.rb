class DataExports::ContactSelection
  DEFAULT_COLUMNS = %w[id name email phone_number labels].freeze
  FILTER_KEYS = %w[attribute_key attribute_model filter_operator query_operator custom_attribute_type values].freeze

  attr_reader :options

  def initialize(account:, user:, options:)
    @account = account
    @user = user
    @options = options.with_indifferent_access.slice(:column_names, :payload, :label, :scope_name)
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
    if options[:payload].present?
      Contacts::FilterService.new(@account, @user, options).perform(count: false).fetch(:contacts)
    elsif options[:label].present?
      @account.contacts.resolved_contacts(use_crm_v2: @account.feature_enabled?('crm_v2')).tagged_with(options[:label], any: true)
    else
      @account.contacts.resolved_contacts(use_crm_v2: @account.feature_enabled?('crm_v2'))
    end
  end

  private

  def validate_shape!
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
      filter['attribute_key'].is_a?(String) && filter['filter_operator'].is_a?(String) && valid_filter_values?(filter)
  end

  def valid_filter_values?(filter)
    strings_valid = %w[query_operator attribute_model custom_attribute_type].all? { |key| filter[key].nil? || filter[key].is_a?(String) }
    strings_valid && filter['values'].is_a?(Array) && filter['values'].all? do |value|
      [String, Numeric, TrueClass, FalseClass].any? do |type|
        value.is_a?(type)
      end
    end
  end
end
