# TODO: logic is written tailored to contact import since its the only import available
# let's break this logic and clean this up in future

class DataImportJob < ApplicationJob
  queue_as :low

  def perform(data_import)
    @data_import = data_import
    process_import_file
    send_failed_records_to_admin
  end

  private

  def process_import_file
    @data_import.update!(status: :processing)

    contacts, rejected_contacts = parse_csv_and_build_contacts

    import_contacts(contacts)
    update_data_import_status(contacts.length, rejected_contacts.length)
    save_failed_records_csv(rejected_contacts)
  end

  def parse_csv_and_build_contacts
    contacts = []
    rejected_contacts = []
    csv = CSV.parse(@data_import.import_file.download, headers: true)

    csv.each do |row|
      current_contact = build_contact(row.to_h.with_indifferent_access, @data_import.account)
      if current_contact.valid?
        contacts << current_contact
      else
        row['errors'] = current_contact.errors.full_messages.join(', ')
        rejected_contacts << row
      end
    end

    [contacts, rejected_contacts]
  end

  def import_contacts(contacts)
    # <struct ActiveRecord::Import::Result failed_instances=[], num_inserts=1, ids=[444, 445], results=[]>
    Contact.import(contacts, synchronize: contacts, on_duplicate_key_ignore: true, track_validation_failures: true, validate: true, batch_size: 1000)
  end

  def update_data_import_status(processed_records, rejected_records)
    @data_import.update!(status: :completed, processed_records: processed_records, total_records: processed_records + rejected_records)
  end

  def build_contact(params, account)
    contact = find_or_initialize_contact(params, account)
    contact.name = params[:name] if params[:name].present?
    contact.additional_attributes ||= {}
    contact.additional_attributes[:company] = params[:company] if params[:company].present?
    contact.additional_attributes[:city] = params[:city] if params[:city].present?
    contact.assign_attributes(custom_attributes: contact.custom_attributes.merge(params.except(:identifier, :email, :name, :phone_number)))
    contact
  end

  def find_or_initialize_contact(params, account)
    contact = find_existing_contact(params, account)
    contact ||= account.contacts.new(params.slice(:email, :identifier, :phone_number))
    contact
  end

  def find_existing_contact(params, account)
    contact = find_contact_by_identifier(params, account)
    contact ||= find_contact_by_email(params, account)
    contact ||= find_contact_by_phone_number(params, account)

    update_contact_with_merged_attributes(params, contact) if contact.present? && contact.valid?
    contact
  end

  def find_contact_by_identifier(params, account)
    return unless params[:identifier]

    account.contacts.find_by(identifier: params[:identifier])
  end

  def find_contact_by_email(params, account)
    return unless params[:email]

    account.contacts.find_by(email: params[:email])
  end

  def find_contact_by_phone_number(params, account)
    return unless params[:phone_number]

    account.contacts.find_by(phone_number: params[:phone_number])
  end

  def update_contact_with_merged_attributes(params, contact)
    contact.email = params[:email] if params[:email].present?
    contact.phone_number = params[:phone_number] if params[:phone_number].present?
    contact.save
  end

  def save_failed_records_csv(rejected_contacts)
    csv_data = generate_csv_data(rejected_contacts)

    return if csv_data.blank?

    @data_import.failed_records.attach(io: StringIO.new(csv_data), filename: "#{Time.zone.today.strftime('%Y%m%d')}_contacts.csv",
                                       content_type: 'text/csv')
    send_failed_records_to_admin
  end

  def generate_csv_data(rejected_contacts)
    headers = CSV.parse(@data_import.import_file.download, headers: true).headers
    headers << 'errors'
    return if rejected_contacts.blank?

    CSV.generate do |csv|
      csv << headers
      rejected_contacts.each do |record|
        csv << record
      end
    end
  end

  def send_failed_records_to_admin
    AdministratorNotifications::ChannelNotificationsMailer.with(account: @data_import.account).failed_records(@data_import).deliver_later
  end
end
