class Companies::DeleteJob < ApplicationJob
  queue_as :low

  BATCH_SIZE = 1000
  CONTACT_COMPANY_NAME_CLEAR_SQL = <<~SQL.squish.freeze
    company_id = NULL,
    additional_attributes = COALESCE(additional_attributes, '{}'::jsonb) - 'company_name'
  SQL

  def perform(company_id)
    company = Company.find_by(id: company_id)
    return if company.blank?

    unlink_contacts(company)
    company.destroy!
  end

  private

  # Keep this out of contact callbacks so unlinking does not dispatch contact automations/webhooks.
  # rubocop:disable Rails/SkipsModelValidations
  def unlink_contacts(company)
    company.contacts.in_batches(of: BATCH_SIZE) do |contacts|
      contacts.update_all(CONTACT_COMPANY_NAME_CLEAR_SQL)
    end
  end
  # rubocop:enable Rails/SkipsModelValidations
end
