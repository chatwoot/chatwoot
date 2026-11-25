require 'json'

class AutomationRules::ConditionsFilterService < FilterService
  ATTRIBUTE_MODEL = 'contact_attribute'.freeze

  def initialize(rule, conversation = nil, options = {})
    super([], nil)
    # assign rule, conversation and account to instance variables
    @rule = rule
    @conversation = conversation
    @account = conversation.account

    # setup filters from json file
    file = File.read('./lib/filters/filter_keys.yml')
    @filters = YAML.safe_load(file)

    @conversation_filters = @filters['conversations']
    @contact_filters = @filters['contacts']
    @message_filters = @filters['messages']

    @options = options
    @changed_attributes = options[:changed_attributes]
  end

  # Captain is asked only when its answer can change the outcome. AND and OR never negate a condition,
  # so a rule that gives the same result with every Captain condition unmet and met gives that result
  # whatever Captain would answer.
  def perform
    return false unless rule_valid?
    return matches?({}) if captain_indexes.empty?

    unmet_result = matches?(captain_indexes.index_with(false))
    return unmet_result if unmet_result == matches?(captain_indexes.index_with(true))

    matches?(Captain::AutomationConditionService.new(
      conditions: @rule.conditions, conversation: @conversation, message: @options[:message]
    ).perform)
  rescue StandardError => e
    Rails.logger.error "Error in AutomationRules::ConditionsFilterService: #{e.message}"
    Rails.logger.info "AutomationRules::ConditionsFilterService failed while processing rule #{@rule.id} for conversation #{@conversation.id}"
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
    # A condition that names an account attribute says so in custom_attribute_type. The standard keys
    # are resolved first below, and message keys are not reserved names -- CustomAttributeDefinition
    # only guards the conversation and contact ones -- so an account attribute called `sender_id` or
    # `content` would otherwise be answered by the message column instead, silently.
    return apply_custom_attribute_filter(query_hash, current_index) if query_hash['custom_attribute_type'].present?

    conversation_filter = @conversation_filters[query_hash['attribute_key']]
    contact_filter = @contact_filters[query_hash['attribute_key']]
    message_filter = @message_filters[query_hash['attribute_key']]

    if query_hash['attribute_key'] == Captain::AutomationConditionService::ATTRIBUTE_KEY
      @query_string += captain_query_string(query_hash, current_index)
    elsif conversation_filter
      @query_string += conversation_query_string('conversations', conversation_filter, query_hash.with_indifferent_access, current_index)
    elsif contact_filter
      @query_string += contact_query_string(contact_filter, query_hash.with_indifferent_access, current_index)
    elsif message_filter
      @query_string += message_query_string(message_filter, query_hash.with_indifferent_access, current_index)
    else
      apply_custom_attribute_filter(query_hash, current_index)
    end
  end

  # custom_attribute_query answers '' when the account has no attribute by that name, so the missing
  # case needs no guard of its own here.
  def apply_custom_attribute_filter(query_hash, current_index)
    # send table name according to attribute key right now we are supporting contact based custom attribute filter
    @query_string += custom_attribute_query(query_hash.with_indifferent_access, query_hash['custom_attribute_type'], current_index)
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
      changed_attribute = @changed_attributes.with_indifferent_access[filter['attribute_key']].presence
      # An event that changed something else carries nothing under this filter's key, and
      # the line below used to index that nil. `perform`'s rescue swallowed the
      # NoMethodError, so the rule was abandoned here with its remaining conditions never
      # evaluated and the whole evaluation answered false -- hundreds of times a day on an
      # account with one such rule, with a log line the only thing to show for it.
      #
      # Answering false directly is what that exception already amounted to, and it is
      # deliberately all this does: it is not the right answer for a rule whose other
      # conditions could still be met on their own, but working that out is not something
      # this method can do. It folds the two halves of a rule -- the conditions that became
      # SQL and the ones that can only be asked of the event -- after `perform` has already
      # dropped where each sat in the chain, so `A AND B OR C` cannot be told from
      # `A AND (B OR C)` here. See #468.
      return @attribute_changed_records = [] if changed_attribute.blank?

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

  # Captain's answer is bound as a boolean so it takes part in the AND/OR chain like any SQL condition.
  def captain_query_string(query_hash, current_index)
    @filter_values["value_#{current_index}"] = @captain_answers[current_index]
    " :value_#{current_index} #{query_hash['query_operator']} "
  end

  def message_query_string(current_filter, query_hash, current_index)
    attribute_key = query_hash['attribute_key']
    query_operator = query_hash['query_operator']

    return sender_id_query_string(query_hash, current_index) if attribute_key == 'sender_id'

    attribute_key = 'processed_message_content' if attribute_key == 'content'
    attribute_key = 'private' if attribute_key == 'private_note'

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

  # The Sender condition offers agents, so it has to mean an agent. messages.sender_id is polymorphic
  # and contacts, users and bots number their rows independently, so an id on its own is satisfied by
  # the contact that happens to hold it too, firing a rule about one agent for a stranger.
  def sender_id_query_string(query_hash, current_index)
    membership = filter_operation(query_hash.merge('filter_operator' => 'equal_to'), current_index)
    clause = "(messages.sender_type = 'User' AND messages.sender_id #{membership})"
    clause = "NOT #{clause}" if query_hash['filter_operator'] == 'not_equal_to'
    " #{clause} #{query_hash['query_operator']} "
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

    if attribute_key == 'assignee_id' && query_hash['filter_operator'].in?(%w[is_present is_not_present])
      return assignee_presence_filter(table_name, query_hash)
    end

    return " #{tag_filter_query(query_hash, current_index)} " if attribute_key == 'labels'

    filter_operator_value = filter_operation(query_hash, current_index)

    case current_filter['attribute_type']
    when 'additional_attributes'
      " #{table_name}.additional_attributes ->> '#{attribute_key}' #{filter_operator_value} #{query_operator} "
    when 'standard'
      " #{table_name}.#{attribute_key} #{filter_operator_value} #{query_operator} "
    end
  end

  private

  def captain_indexes
    @captain_indexes ||= @rule.conditions.each_index.select do |index|
      @rule.conditions[index]['attribute_key'] == Captain::AutomationConditionService::ATTRIBUTE_KEY
    end
  end

  def matches?(captain_answers)
    @captain_answers = captain_answers
    @query_string = ''
    @filter_values = {}
    @attribute_changed_query_filter = []

    @rule.conditions.each_with_index do |query_hash, current_index|
      @attribute_changed_query_filter << query_hash and next if query_hash['filter_operator'] == 'attribute_changed'

      apply_filter(query_hash, current_index)
    end

    records = base_relation.where(@query_string, @filter_values.with_indifferent_access)
    records = perform_attribute_changed_filter(records) if @attribute_changed_query_filter.any?

    records.any?
  end

  def filter_config
    {
      entity: 'Conversation',
      table_name: 'conversations'
    }
  end

  def base_relation
    records = Conversation.where(id: @conversation.id).joins(
      'LEFT OUTER JOIN contacts on conversations.contact_id = contacts.id'
    ).joins(
      'LEFT OUTER JOIN messages on messages.conversation_id = conversations.id'
    )

    records = records.where(messages: { id: @options[:message].id }) if @options[:message].present?
    records
  end
end
