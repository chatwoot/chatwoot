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
  CONTACT_COMPANY_NAME_CLEANUP_KEY = '_company_name_cleanup'.freeze
  CONTACT_COMPANY_NAME_CLEANUP_SQL = <<~SQL.squish.freeze
    additional_attributes = CASE
      WHEN company_id IS NULL AND additional_attributes ->> 'company_name' = additional_attributes #>> '{_company_name_cleanup,company_name}'
      THEN additional_attributes - 'company_name' - '_company_name_cleanup'
      ELSE additional_attributes - '_company_name_cleanup'
    END
  SQL

  def perform(company_id: nil, cleanup_company_id: nil)
    return if company_id.blank? && cleanup_company_id.blank?

    return clear_marked_company_names(cleanup_company_id) if cleanup_company_id.present?

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

  def clear_marked_company_names(cleanup_company_id)
    Contact.where("additional_attributes #>> '{#{CONTACT_COMPANY_NAME_CLEANUP_KEY},company_id}' = ?", cleanup_company_id.to_s)
           .update_all(CONTACT_COMPANY_NAME_CLEANUP_SQL)
  end
  # rubocop:enable Rails/SkipsModelValidations
end
