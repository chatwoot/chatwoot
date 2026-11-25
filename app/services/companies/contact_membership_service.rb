class Companies::ContactMembershipService
  attr_reader :company

  def initialize(company:)
    @company = company
  end

  def assign(contact:)
    contact.with_lock { contact.update!(company: company) }
    company.record_activity_at!(contact.last_activity_at) if contact.last_activity_at.present?
  end

  def remove(contact:)
    contact.with_lock do
      contact.update!(company: nil) if contact.company_id == company.id
    end
  end
end
