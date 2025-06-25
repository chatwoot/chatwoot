class Crm::Leadsquared::LeadFinderService
  def initialize(lead_client)
    @lead_client = lead_client
  end

  def find_or_create(contact)
    lead_id = get_stored_id(contact)
    return lead_id if lead_id.present?

    lead_id = find_by_contact(contact)
    return lead_id if lead_id.present?

    create_lead(contact)
  end

  private

  def find_by_contact(contact)
    lead_id = find_by_email(contact)
    lead_id = find_by_phone_number(contact) if lead_id.blank?

    lead_id
  end

  def find_by_email(contact)
    return if contact.email.blank?

    search_by_field(contact.email)
  end

  def find_by_phone_number(contact)
    return if contact.phone_number.blank?

    search_by_field(contact.phone_number)
  end

  def search_by_field(value)
    leads = @lead_client.search_lead(value)
    return nil unless leads.is_a?(Array)

    leads.first['ProspectID'] if leads.any?
  end

  def create_lead(contact)
    lead_data = Crm::Leadsquared::Mappers::ContactMapper.map(contact)
    lead_id = @lead_client.create_or_update_lead(lead_data)

    raise StandardError, 'Failed to create lead - no ID returned' if lead_id.blank?

    lead_id
  end

  def get_stored_id(contact)
    return nil if contact.additional_attributes.blank?
    return nil if contact.additional_attributes['external'].blank?

    contact.additional_attributes.dig('external', 'leadsquared_id')
  end
end
