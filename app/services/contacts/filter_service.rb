class Contacts::FilterService < FilterService
  ATTRIBUTE_MODEL = 'contact_attribute'.freeze

  def initialize(params, user, filter_account = nil)
    @account = filter_account || Current.account
    super(params, user)
  end

  def perform
    @contacts = query_builder(@filters['contacts'])
    @contacts = contacts_by_stage_type(@contacts) if @params[:stage_type].present?
    @contacts = contacts_by_stage_code(@contacts) if @params[:stage_code].present?

    {
      contacts: @contacts,
      count: @contacts.count
    }
  end

  def contacts_by_stage_type(contacts)
    stage_type = Stage::STAGE_TYPE_MAPPING[@params[:stage_type]]
    both_type = Stage::STAGE_TYPE_MAPPING['both']
    contacts.joins(:stage)
            .where("stages.stage_type = #{stage_type} or stages.stage_type = #{both_type} or #{stage_type} = #{both_type}")
  end

  def contacts_by_stage_code(contacts)
    stage = @account.stages.find_by(code: @params[:stage_code])
    contacts.where(stage_id: stage.id)
  end

  def product_filter_query(query_hash, current_index)
    combined_query = custom_attribute_query(query_hash, 'product_attribute', current_index)
    "contacts.product_id IN (SELECT products.id from products WHERE #{combined_query})"
  end

  def conversation_plan_filter_query(query_hash)
    table_name = filter_config[:table_name]
    query_operator = query_hash[:query_operator]

    combined_query = build_conversation_plan_combined_query(query_hash)

    conversation_plan_query =
      "#{table_name}.id IN (SELECT conversation_plans.contact_id FROM conversation_plans #{combined_query})"

    "#{conversation_plan_query} #{query_operator}"
  end

  def build_conversation_plan_combined_query(query_hash)
    combined_query_array = []

    case filter_values(query_hash) # NOTICE: when 'all' => DO NOTHING
    when 'today'
      combined_query_array << 'conversation_plans.completed_at IS NULL AND conversation_plans.snoozed_until::date = now()::date'
    when 'this_week'
      beginning_of_week = Time.zone.now.at_beginning_of_week.to_fs(:db)
      end_of_week = Time.zone.now.at_end_of_week.to_fs(:db)
      combined_query_array <<
        "conversation_plans.completed_at IS NULL AND conversation_plans.snoozed_until >= timestamp '#{beginning_of_week}' " \
        "AND conversation_plans.snoozed_until < timestamp '#{end_of_week}'"
    when 'unresolved'
      combined_query_array << 'conversation_plans.completed_at IS NULL'
    end

    combined_query_array.present? ? "WHERE #{combined_query_array.join(' AND ')}" : ''
  end

  def filter_values(query_hash)
    current_val = query_hash['values'][0]
    if query_hash['attribute_key'] == 'phone_number'
      "+#{current_val}"
    elsif query_hash['attribute_key'] == 'country_code'
      current_val.downcase
    else
      current_val.is_a?(String) ? current_val.downcase : current_val
    end
  end

  def base_relation
    @account.contacts
  end

  def filter_config
    {
      entity: 'Contact',
      table_name: 'contacts'
    }
  end

  private

  def equals_to_filter_string(filter_operator, current_index)
    return "= :value_#{current_index}" if filter_operator == 'equal_to'

    "!= :value_#{current_index}"
  end
end
