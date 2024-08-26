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
