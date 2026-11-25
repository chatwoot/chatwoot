class Companies::DeleteJob < ApplicationJob
  queue_as :low

  BATCH_SIZE = 1000
  CONTACT_COMPANY_CLEAR_SQL = <<~SQL.squish.freeze
    company_id = NULL,
    additional_attributes = COALESCE(additional_attributes, '{}'::jsonb) - 'company_name'
  SQL

  def perform(company_id:)
    company = Company.find_by(id: company_id)
    return if company.blank?

    clear_contact_company_names(company)
    company.destroy!
  end

  private

  # Avoid contact callbacks so this cleanup does not dispatch contact automations/webhooks.
  # rubocop:disable Rails/SkipsModelValidations
  def clear_contact_company_names(company)
    company.contacts.in_batches(of: BATCH_SIZE) do |contacts|
      contacts.update_all(CONTACT_COMPANY_CLEAR_SQL)
    end
  end
  # rubocop:enable Rails/SkipsModelValidations
end
