class Contacts::CompanyAssociationService
  def associate_company_from_email(contact)
    return nil if skip_association?(contact)

    company = find_or_create_company(contact)
    # rubocop:disable Rails/SkipsModelValidations
    # Intentionally using update_column here to:
    # 1. Avoid triggering callbacks
    # 2. Improve performance (We're only setting company_id, no need for validation)
    contact.update_column(:company_id, company.id) if company
    # rubocop:enable Rails/SkipsModelValidations
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
