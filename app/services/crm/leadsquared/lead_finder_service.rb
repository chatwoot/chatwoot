class Crm::Leadsquared::LeadFinderService
  def initialize(lead_client)
    @lead_client = lead_client
  end

  def find_or_create(contact)
    # First check if we already have a stored ID
    lead_id = get_external_id(contact)
    return { success: true, lead_id: lead_id } if lead_id.present?

    # If not, search for it in LeadSquared
    found_lead = find_by_contact(contact)
    return found_lead if found_lead[:success]

    # If still not found, create a new lead
    create_lead(contact)
  end

  private

  def find_by_contact(contact)
    if contact.email.present?
      result = search_by_field(contact.email)
      return result if result[:success]
    end

    if contact.phone_number.present?
      result = search_by_field(contact.phone_number)
      return result if result[:success]
    end

    { success: false }
  end

  def search_by_field(value)
    response = @lead_client.search_lead(value)
    return { success: false } unless response[:success] && response[:data].is_a?(Array) && response[:data].any?

    { success: true, lead_id: response[:data].first['ProspectID'] }
  end

  def create_lead(contact)
    lead_data = Crm::Leadsquared::Mappers::ContactMapper.map(contact)
    response = @lead_client.create_or_update_lead(lead_data)

    if response[:success]
      lead_id = response[:data]['Id']
      return { success: true, lead_id: lead_id } if lead_id.present?
    end

    { success: false, error: 'Failed to create lead' }
  end

  def get_external_id(contact)
    return nil if contact.additional_attributes.blank?
    return nil if contact.additional_attributes['external'].blank?

    contact.additional_attributes.dig('external', 'leadsquared_id')
  end
end
