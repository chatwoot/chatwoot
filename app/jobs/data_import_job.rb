# TODO: logic is written tailored to contact import since its the only import available
# let's break this logic and clean this up in future

class DataImportJob < ApplicationJob
  queue_as :low

  def perform(data_import)
    contacts = []
    rejected_contacts = []
    @data_import = data_import
    @data_import.update!(status: :processing)
    csv = CSV.parse(@data_import.import_file.download, headers: true)
    csv.each { |row| contacts << build_contact(row.to_h.with_indifferent_access, @data_import.account) }
    contacts.each_slice(1000) do |contact_chunks|
      rejected_contacts << contact_chunks.reject { |contact| contact.valid? && contact.save! }
    end
    rejected_contacts = rejected_contacts.flatten
    @data_import.update!(status: :completed, processed_records: (csv.length - rejected_contacts.length), total_records: csv.length)
    save_invalid_records_csv(rejected_contacts)
  end

  private

  def build_contact(params, account)
    # TODO: rather than doing the find or initialize individually lets fetch objects in bulk and update them in memory
    contact = init_contact(params, account)

    contact.name = params[:name] if params[:name].present?
    contact.assign_attributes(custom_attributes: contact.custom_attributes.merge(params.except(:identifier, :email, :name, :phone_number)))
    contact
  end

  # add the phone number check here
  def get_identified_contacts(params, account)
    identifier_contact = account.contacts.find_by(identifier: params[:identifier]) if params[:identifier]
    email_contact = account.contacts.find_by(email: params[:email]) if params[:email]
    phone_number_contact = account.contacts.find_by(phone_number: params[:phone_number]) if params[:phone_number]
    contact = merge_identified_contact_attributes(params, [identifier_contact, email_contact, phone_number_contact])
    # intiating the new contact / contact attributes only by ensuring the identifier, email or phone_number duplication errors won't occur
    contact ||= merge_contact(email_contact, phone_number_contact)
    contact
  end

  def merge_contact(email_contact, phone_number_contact)
    contact ||= email_contact
    contact ||= phone_number_contact
    contact
  end

  def merge_identified_contact_attributes(params, available_contacts)
    identifier_contact, email_contact, phone_number_contact = available_contacts
    contact = identifier_contact
    contact&.email = params[:email] if params[:email].present? && email_contact.blank?
    contact&.phone_number = params[:phone_number] if params[:phone_number].present? && phone_number_contact.blank?
    contact
  end

  def save_invalid_records_csv(rejected_contacts)
    return if rejected_contacts.blank?

    csv_string = CSV.generate do |csv|
      csv << %w[id name email phone_number identifier errors]
      rejected_contacts.each do |record|
        csv << [record['id'], record['name'], record['email'], record['phone_number'], record['identifier'], record.errors.full_messages.join(',')]
      end
    end

    mailer = ActionMailer::Base.new
    mailer.attachments['erroneous_contact.csv'] = csv_string
    mailer.mail(
      from: ENV.fetch('MAILER_SENDER_EMAIL', nil),
      to: @data_import.account.administrators.pluck(:email),
      subject: "Contact Import failed on #{Time.zone.today.strftime('%d-%m-%Y')}",
      body: 'See attachment'
    )
    mailer.message.deliver
  end

  def init_contact(params, account)
    contact = get_identified_contacts(params, account)
    contact ||= account.contacts.new(params.slice(:email, :identifier, :phone_number))
    contact
  end
end
