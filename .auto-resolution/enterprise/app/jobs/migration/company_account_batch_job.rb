class Migration::CompanyAccountBatchJob < ApplicationJob
  queue_as :low

  def perform(account)
    account.contacts
           .where.not(email: nil)
           .find_in_batches(batch_size: 1000) do |contact_batch|
      process_contact_batch(contact_batch, account)
    end
  end

  private

  def process_contact_batch(contacts, account)
    contacts.each do |contact|
      next unless should_process?(contact)

      company = find_or_create_company(contact, account)
      # rubocop:disable Rails/SkipsModelValidations
      contact.update_column(:company_id, company.id) if company
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  def should_process?(contact)
    return false if contact.company_id.present?
    return false if contact.email.blank?

    Companies::BusinessEmailDetectorService.new(contact.email).perform
  end

  def find_or_create_company(contact, account)
    domain = extract_domain(contact.email)
    company_name = derive_company_name(contact, domain)

    Company.find_or_create_by!(account: account, domain: domain) do |company|
      company.name = company_name
    end
  rescue ActiveRecord::RecordNotUnique
    # Race condition: Another job created it between our check and create
    # just find the one that was created

    Company.find_by(account: account, domain: domain)
  end

  def extract_domain(email)
    email.split('@').last&.downcase
  end

  def derive_company_name(contact, domain)
    contact.additional_attributes&.dig('company_name').presence ||
      domain.split('.').first.tr('-_', ' ').titleize
  end
end
