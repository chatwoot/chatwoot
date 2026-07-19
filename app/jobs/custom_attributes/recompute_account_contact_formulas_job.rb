class CustomAttributes::RecomputeAccountContactFormulasJob < ApplicationJob
  queue_as :low

  def perform(account_id)
    account = Account.find_by(id: account_id)
    return if account.blank?
    return unless account.custom_attribute_definitions.contact_attribute.where.not(formula: nil).exists?

    account.contacts.find_each(batch_size: 100) do |contact|
      CustomAttributes::RecomputeContactFormulasService.new(contact: contact).perform
    rescue StandardError => e
      Rails.logger.warn(
        "[RecomputeAccountContactFormulasJob] contact=#{contact.id} error=#{e.class}: #{e.message}"
      )
    end
  end
end
