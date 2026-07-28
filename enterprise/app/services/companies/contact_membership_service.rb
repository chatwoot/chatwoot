class Companies::ContactMembershipService
  attr_reader :company

  def initialize(company:)
    @company = company
  end

  def assign(contact:)
    contact.update!(company: company)
    company.record_activity_at!(contact.last_activity_at) if contact.last_activity_at.present?
  end

  def remove(contact:)
    contact.update!(company: nil)
  end
end
