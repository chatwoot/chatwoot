require 'json'

class AutomationRules::ConditionsFilterService < FilterService
  ATTRIBUTE_MODEL = 'contact_attribute'.freeze

  def initialize(rule, event_object, options = {})
    super([], nil)
    # Assign rule, event_object_type, event_object and account to instance variables
    @rule = rule
    @event_object = event_object.reload
    @event_object_type = get_type_of(event_object)
    @account = event_object.account

    # setup filters from json file
    file = File.read('./lib/filters/filter_keys.yml')
    @filters = YAML.safe_load(file)

    @conversation_filters = @filters['conversations']
    @contact_filters = @filters['contacts']
    @message_filters = @filters['messages']

    @options = options
    @changed_attributes = options[:changed_attributes]
  end

  def perform
    return false unless rule_valid?

    @attribute_changed_query_filter = []

    @rule.conditions.each_with_index do |query_hash, current_index|
      @attribute_changed_query_filter << query_hash and next if query_hash['filter_operator'] == 'attribute_changed'

      apply_filter(query_hash, current_index)
    end

    records = base_relation.where(@query_string, @filter_values.with_indifferent_access)
    records = perform_attribute_changed_filter(records) if @attribute_changed_query_filter.any?

    records.any?
  rescue StandardError => e
    Rails.logger.error "Error in AutomationRules::ConditionsFilterService: #{e.message}"
    Rails.logger.info 'AutomationRules::ConditionsFilterService failed while ' \
                      "processing rule #{@rule.id} for #{@event_object_type} #{@event_object.id}"
    false
  end

  def rule_valid?
    is_valid = AutomationRules::ConditionValidationService.new(@rule).perform
    Rails.logger.info "Automation rule condition validation failed for rule id: #{@rule.id}" unless is_valid
    @rule.authorization_error! unless is_valid

    is_valid
  end

  def filter_operation(query_hash, current_index)
    if query_hash[:filter_operator] == 'starts_with'
      @filter_values["value_#{current_index}"] = "#{string_filter_values(query_hash)}%"
      like_filter_string(query_hash[:filter_operator], current_index)
    else
      super
    end
  end

  def apply_filter(query_hash, current_index)
    current_filter = find_current_filter(attribute_key: query_hash['attribute_key'])
    conversation_filter, contact_filter, message_filter =
      current_filter.values_at(:conversation_filters, :contact_filter, :message_filter)

    # Calculate @query_string variable instance if present
    if conversation_filter
      @query_string += conversation_query_string('conversations', conversation_filter, query_hash.with_indifferent_access, current_index)
    elsif contact_filter
      @query_string += contact_query_string(contact_filter, query_hash.with_indifferent_access, current_index)
    elsif message_filter
      @query_string += message_query_string(message_filter, query_hash.with_indifferent_access, current_index)
    elsif custom_attribute(query_hash['attribute_key'], @account, query_hash['custom_attribute_type'])
      @query_string += custom_attribute_query(query_hash.with_indifferent_access, query_hash['custom_attribute_type'], current_index)
    end
  end

  def find_current_filter(attribute_key:)
    case @event_object_type
    when :conversation
      conversation_filter = @event_object_type == :message
      message_filter = @message_filters[attribute_key] if conversation_filter.blank?
      { conversation_filter: conversation_filter, message_filter: message_filter }
    when :contact
      contact_filter = @contact_filters[attribute_key]
      { contact_filter: contact_filter }
    when :message
      message_filter = @message_filters[attribute_key]
      { message_filter: message_filter }
    else
      {}
    end
  end

  # If attribute_changed type filter is present perform this against array
  def perform_attribute_changed_filter(records)
    @attribute_changed_records = []
    current_attribute_changed_record = base_relation
    filter_based_on_attribute_change(records, current_attribute_changed_record)

    @attribute_changed_records.uniq
  end

  # Loop through attribute_changed_query_filter
  def filter_based_on_attribute_change(records, current_attribute_changed_record)
    @attribute_changed_query_filter.each do |filter|
      @changed_attributes = @changed_attributes.with_indifferent_access
      changed_attribute = @changed_attributes[filter['attribute_key']].presence

      if changed_attribute[0].in?(filter['values']['from']) && changed_attribute[1].in?(filter['values']['to'])
        @attribute_changed_records = attribute_changed_filter_query(filter, records, current_attribute_changed_record)
      end
      current_attribute_changed_record = @attribute_changed_records
    end
  end

  # We intersect with the record if query_operator-AND is present and union if query_operator-OR is present
  def attribute_changed_filter_query(filter, records, current_attribute_changed_record)
    if filter['query_operator'] == 'AND'
      @attribute_changed_records + (current_attribute_changed_record & records)
    else
      @attribute_changed_records + (current_attribute_changed_record | records)
    end
  end

  def message_query_string(current_filter, query_hash, current_index)
    attribute_key = query_hash['attribute_key']
    query_operator = query_hash['query_operator']

    attribute_key = 'processed_message_content' if attribute_key == 'content'

    filter_operator_value = filter_operation(query_hash, current_index)

    case current_filter['attribute_type']
    when 'standard'
      if current_filter['data_type'] == 'text'
        " LOWER(messages.#{attribute_key}) #{filter_operator_value} #{query_operator} "
      else
        " messages.#{attribute_key} #{filter_operator_value} #{query_operator} "
      end
    end
  end

  # This will be used in future for contact automation rule
  def contact_query_string(current_filter, query_hash, current_index)
    attribute_key = query_hash['attribute_key']
    query_operator = query_hash['query_operator']

    filter_operator_value = filter_operation(query_hash, current_index)

    case current_filter['attribute_type']
    when 'additional_attributes'
      " contacts.additional_attributes ->> '#{attribute_key}' #{filter_operator_value} #{query_operator} "
    when 'standard'
      " contacts.#{attribute_key} #{filter_operator_value} #{query_operator} "
    end
  end

  def conversation_query_string(table_name, current_filter, query_hash, current_index)
    attribute_key = query_hash['attribute_key']
    query_operator = query_hash['query_operator']
    filter_operator_value = filter_operation(query_hash, current_index)

    case current_filter['attribute_type']
    when 'additional_attributes'
      " #{table_name}.additional_attributes ->> '#{attribute_key}' #{filter_operator_value} #{query_operator} "
    when 'standard'
      if attribute_key == 'labels'
        " tags.id #{filter_operator_value} #{query_operator} "
      else
        " #{table_name}.#{attribute_key} #{filter_operator_value} #{query_operator} "
      end
    end
  end

  private

  def get_type_of(event_object)
    if event_object.instance_of?(Conversation)
      :conversation
    elsif event_object.instance_of?(Contact)
      :contact
    elsif event_object.instance_of?(Message)
      :message
    else
      raise "Unsupported operation for this event_object type: #{@event_object.class.name}"
    end
  end

  def base_relation
    case @event_object_type
    when :conversation
      Conversation.where(id: @event_object.id)
                  .joins('LEFT OUTER JOIN contacts on conversations.contact_id = contacts.id')
    when :message
      conversation = @event_object.send(:conversation)
      Conversation.where(id: conversation.id)
                  .joins('LEFT OUTER JOIN contacts on conversations.contact_id = contacts.id')
                  .joins('LEFT OUTER JOIN messages on messages.conversation_id = conversations.id')
                  .where(messages: { id: @event_object.id })
    when :contact
      Contact.where(id: @event_object.id).joins('LEFT OUTER JOIN products on contacts.product_id = products.id')
    end
  end
end
