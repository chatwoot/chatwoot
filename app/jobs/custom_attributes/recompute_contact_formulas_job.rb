class CustomAttributes::RecomputeContactFormulasJob < ApplicationJob
  queue_as :low

  def perform(contact_id)
    contact = Contact.find_by(id: contact_id)
    return if contact.blank?

    CustomAttributes::RecomputeContactFormulasService.new(contact: contact).perform
  end
end
