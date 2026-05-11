class Companies::ContactMembershipService
  attr_reader :company

  def initialize(company:)
    @company = company
  end

  def assign(contact:)
    contact.update!(company: company)
  end

  def remove(contact:)
    contact.update!(company: nil)
  end
end
