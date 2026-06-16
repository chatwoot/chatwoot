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

  def perform(company_id: nil, company_name: nil, contact_ids: nil)
    return if company_id.blank? && contact_ids.blank?

    contacts = contact_ids.present? ? Contact.where(id: contact_ids) : Contact.where(company_id: company_id)

    if company_name.present?
      sync_company_name(contacts, company_name)
    else
      clear_company_name(contacts)
    end
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
end
