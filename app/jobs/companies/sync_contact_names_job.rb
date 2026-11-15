class Companies::SyncContactNamesJob < ApplicationJob
  queue_as :low

  BATCH_SIZE = 1000
  CONTACT_COMPANY_NAME_UPDATE_SQL = <<~SQL.squish.freeze
    additional_attributes = jsonb_set(
      COALESCE(additional_attributes, '{}'::jsonb),
      '{company_name}',
      ?::jsonb,
      true
    )
  SQL

  def perform(company_id:)
    return if company_id.blank?

    company = Company.find_by(id: company_id)
    return if company.blank?

    sync_company_name(company)
  end

  private

  # Denormalized display field sync; avoid contact validations, callbacks, and webhook/automation side effects.
  # rubocop:disable Rails/SkipsModelValidations
  def sync_company_name(company)
    company.contacts.in_batches(of: BATCH_SIZE) do |contacts|
      contacts.update_all([CONTACT_COMPANY_NAME_UPDATE_SQL, company.name.to_json])
    end
  end
  # rubocop:enable Rails/SkipsModelValidations
end
