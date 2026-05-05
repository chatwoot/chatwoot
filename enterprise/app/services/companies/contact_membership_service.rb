class Companies::ContactMembershipService
  attr_reader :company

  def initialize(company:)
    @company = company
  end

  def assign(contact:)
    sync_contact(contact, company_id: company.id, company_name: company.name)
  end

  def remove(contact:)
    sync_contact(contact, company_id: nil, company_name: nil)
  end

  def sync_company_name
    company.contacts.find_each do |contact|
      sync_contact(contact, company_id: company.id, company_name: company.name)
    end
  end

  def cleanup_on_company_delete
    company.contacts.find_each do |contact|
      sync_contact(contact, company_id: nil, company_name: nil)
    end
  end

  private

  def sync_contact(contact, company_id:, company_name:)
    contact.update!(
      company_id: company_id,
      additional_attributes: synced_additional_attributes(contact, company_name)
    )
  end

  def synced_additional_attributes(contact, company_name)
    attributes = contact.additional_attributes || {}
    return attributes.excluding('company_name') if company_name.blank?

    attributes.merge('company_name' => company_name)
  end
end
