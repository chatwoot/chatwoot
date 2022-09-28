# TODO: logic is written tailored to contact import since its the only import available
# let's break this logic and clean this up in future

class DataImportJob < ApplicationJob
  queue_as :low

  def perform(data_import)
    contacts = []
    data_import.update!(status: :processing)
    csv = CSV.parse(data_import.import_file.download, headers: true)
    csv.each { |row| contacts << build_contact(row.to_h.with_indifferent_access, data_import.account) }
    result = Contact.import contacts, on_duplicate_key_update: :all, batch_size: 1000
    data_import.update!(status: :completed, processed_records: csv.length - result.failed_instances.length, total_records: csv.length)
  end

  private

  def build_contact(params, account)
    # TODO: rather than doing the find or initialize individually lets fetch objects in bulk and update them in memory
    contact = init_contact(params, account)

    contact.name = params[:name] if params[:name].present?
    contact.assign_attributes(custom_attributes: contact.custom_attributes.merge(params.except(:identifier, :email, :name)))
    contact
  end

  def get_identified_contacts(params, account)
    identifier_contact = account.contacts.find_by(identifier: params[:identifier]) if params[:identifier]
    email_contact = account.contacts.find_by(email: params[:email]) if params[:email]
    [identifier_contact, email_contact]
  end

  def init_contact(params, account)
    identifier_contact, email_contact = get_identified_contacts(params, account)

    # intiating the new contact / contact attributes only by ensuring the identifier or email duplication errors won't occur
    contact = identifier_contact
    contact&.email = params[:email] if params[:email].present? && email_contact.blank?
    contact ||= email_contact
    contact ||= account.contacts.new(params.slice(:email, :identifier))
    contact
  end
end
