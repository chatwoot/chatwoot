# TODO: logic is written tailored to contact import since its the only import available
# let's break this logic and clean this up in future

class DataImportJob < ApplicationJob
  queue_as :low

  def perform(data_import)
    contacts = []
    CSV.parse(data_import.import_file.download, headers: true) do |row|
      contacts << build_contact(row.to_h.with_indifferent_access, data_import.account)
    end
    Contact.import contacts
  end

  private

  def build_contact(params, account)
    # TODO: rather than doing the find or initialize individually lets fetch objects in bulk and update them in memory
    key_attributes = [:identifier, :email, :name]
    contact = account.contacts.find_or_initialize_by(identifier: params[:identifier]) if params[:identifier]
    contact ||= account.contacts.find_or_initialize_by(email: params[:email]) if params[:email]
    contact ||= account.contacts.new
    contact.assign_attributes(params.slice(*key_attributes))
    contact.assign_attributes(custom_attributes: contact.custom_attributes.merge(params.except(*key_attributes)))
    contact
  end
end
