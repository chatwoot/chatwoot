class Companies::SyncContactNamesJob < ApplicationJob
  queue_as :low

  CONTACT_COMPANY_NAME_UPDATE_SQL = <<~SQL.squish.freeze
    additional_attributes = jsonb_set(
      COALESCE(additional_attributes, '{}'::jsonb),
      '{company_name}',
      ?::jsonb,
      true
    )
  SQL
  CONTACT_COMPANY_NAME_DELETE_SQL = "additional_attributes = COALESCE(additional_attributes, '{}'::jsonb) - 'company_name'".freeze

  def perform(company_id: nil, account_id: nil, company_name: nil)
    return if company_id.blank? && (account_id.blank? || company_name.blank?)

    return clear_company_name(unassigned_contacts_with_company_name(account_id, company_name)) if account_id.present? && company_name.present?

    company = Company.find_by(id: company_id)
    return if company.blank?

    sync_company_name(Contact.where(company_id: company.id), company.name)
  end

  private

  # Denormalized display field sync; avoid contact validations, callbacks, and webhook/automation side effects.
  # rubocop:disable Rails/SkipsModelValidations
  def sync_company_name(contacts, company_name)
    contacts.update_all([CONTACT_COMPANY_NAME_UPDATE_SQL, company_name.to_json])
  end

  def clear_company_name(contacts)
    contacts.update_all(CONTACT_COMPANY_NAME_DELETE_SQL)
  end
  # rubocop:enable Rails/SkipsModelValidations

  def unassigned_contacts_with_company_name(account_id, company_name)
    Contact.where(account_id: account_id, company_id: nil)
           .where("additional_attributes ->> 'company_name' = ?", company_name)
  end
end
