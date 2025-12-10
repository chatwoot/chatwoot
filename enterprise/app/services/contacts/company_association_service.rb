class Contacts::CompanyAssociationService
  def associate_company_from_email(contact)
    return nil if skip_association?(contact)

    company = find_or_create_company(contact)
    if company
      # rubocop:disable Rails/SkipsModelValidations
      # Using update_column and increment_counter to avoid triggering callbacks while maintaining counter cache
      contact.update_column(:company_id, company.id)
      Company.increment_counter(:contacts_count, company.id)
      # rubocop:enable Rails/SkipsModelValidations
    end
    company
  end

  private

  def skip_association?(contact)
    return true if contact.company_id.present?
    return true if contact.email.blank?

    detector = Companies::BusinessEmailDetectorService.new(contact.email)
    return true unless detector.perform

    false
  end

  def find_or_create_company(contact)
    domain = extract_domain(contact.email)
    company_name = derive_company_name(contact, domain)

    Company.find_or_create_by!(account: contact.account, domain: domain) do |company|
      company.name = company_name
    end
  rescue ActiveRecord::RecordNotUnique
    # If another process created it first, just find that
    Company.find_by(account: contact.account, domain: domain)
  end

  def extract_domain(email)
    email.split('@').last&.downcase
  end

  def derive_company_name(contact, domain)
    contact.additional_attributes&.dig('company_name') || domain.split('.').first.tr('-_', ' ').titleize
  end
end
