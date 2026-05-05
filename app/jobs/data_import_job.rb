# TODO: logic is written tailored to contact import since its the only import available
# let's break this logic and clean this up in future

class DataImportJob < ApplicationJob
  queue_as :low
  retry_on ActiveStorage::FileNotFoundError, wait: 1.minute, attempts: 3

  LABELS_DELIMITER = ','.freeze
  LABELS_CONTEXT = 'labels'.freeze
  CONTACT_TAGGABLE_TYPE = 'Contact'.freeze

  def perform(data_import)
    @data_import = data_import
    @contact_manager = DataImport::ContactManager.new(@data_import.account)
    begin
      process_import_file
      send_import_notification_to_admin
    rescue CSV::MalformedCSVError => e
      handle_csv_error(e)
    end
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

    with_import_file do |file|
      csv_reader(file).each do |row|
        build_contact_from_row(row, contacts, rejected_contacts)
      end
    end

    [contacts, rejected_contacts]
  end

  def build_contact_from_row(row, contacts, rejected_contacts)
    row_hash = row.to_h.with_indifferent_access
    labels = extract_labels(row_hash)
    invalid_labels = unapproved_labels(labels)

    if invalid_labels.present?
      append_label_error(row, invalid_labels, rejected_contacts)
      return
    end

    current_contact = @contact_manager.build_contact(row_hash.except(:labels))
    if current_contact.valid?
      contacts << { contact: current_contact, labels: labels }
    else
      append_rejected_contact(row, current_contact, rejected_contacts)
    end
  end

  def extract_labels(row_hash)
    return [] if row_hash[:labels].blank?

    row_hash[:labels].to_s.split(LABELS_DELIMITER).map(&:strip).reject(&:blank?)
  end

  def unapproved_labels(labels)
    labels.map(&:downcase) - approved_labels
  end

  def append_rejected_contact(row, contact, rejected_contacts)
    row['errors'] = contact.errors.full_messages.join(', ')
    rejected_contacts << row
  end

  def import_contacts(contacts_with_labels)
    contacts = contacts_with_labels.pluck(:contact)
    # <struct ActiveRecord::Import::Result failed_instances=[], num_inserts=1, ids=[444, 445], results=[]>
    Contact.import(contacts, synchronize: contacts, on_duplicate_key_ignore: true, track_validation_failures: true, validate: true, batch_size: 1000)
    apply_labels_to_contacts(contacts_with_labels)
  end

  def apply_labels_to_contacts(contacts_with_labels)
    taggings = taggings_for_contacts(contacts_with_labels)
    return if taggings.blank?

    # Bulk insert mirrors the contact import path and avoids Contact update callbacks for label application.
    # rubocop:disable Rails/SkipsModelValidations
    ActsAsTaggableOn::Tagging.insert_all(taggings)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def taggings_for_contacts(contacts_with_labels)
    taggings = contacts_with_labels.filter_map do |item|
      contact = item[:contact]
      labels = item[:labels].map(&:downcase).uniq
      # After bulk import with synchronize, contact is marked as persisted for successfully imported records.
      next unless contact.persisted? && labels.present?

      labels.map do |label|
        {
          tag_id: tags_by_name[label].id,
          taggable_type: CONTACT_TAGGABLE_TYPE,
          taggable_id: contact.id,
          context: LABELS_CONTEXT,
          created_at: Time.zone.now
        }
      end
    end.flatten.uniq

    reject_existing_taggings(taggings)
  end

  def reject_existing_taggings(taggings)
    taggable_ids = taggings.pluck(:taggable_id)
    tag_ids = taggings.pluck(:tag_id)
    existing_taggings = ActsAsTaggableOn::Tagging
                        .where(context: LABELS_CONTEXT, taggable_type: CONTACT_TAGGABLE_TYPE, taggable_id: taggable_ids, tag_id: tag_ids)
                        .pluck(:tag_id, :taggable_id)
                        .index_with(true)

    taggings.reject { |tagging| existing_taggings[[tagging[:tag_id], tagging[:taggable_id]]] }
  end

  def tags_by_name
    @tags_by_name ||= ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name(approved_labels).index_by { |tag| tag.name.downcase }
  end

  def approved_labels
    @approved_labels ||= @data_import.account.labels.pluck(:title)
  end

  def append_label_error(row, labels, rejected_contacts)
    row['errors'] = "Unknown labels: #{labels.join(', ')}"
    rejected_contacts << row
  end

  def update_data_import_status(processed_records, rejected_records)
    @data_import.update!(status: :completed, processed_records: processed_records, total_records: processed_records + rejected_records)
  end

  def save_failed_records_csv(rejected_contacts)
    csv_data = generate_csv_data(rejected_contacts)
    return if csv_data.blank?

    @data_import.failed_records.attach(io: StringIO.new(csv_data), filename: "#{Time.zone.today.strftime('%Y%m%d')}_contacts.csv",
                                       content_type: 'text/csv')
  end

  def generate_csv_data(rejected_contacts)
    headers = csv_headers
    headers << 'errors'
    return if rejected_contacts.blank?

    CSV.generate do |csv|
      csv << headers
      rejected_contacts.each do |record|
        csv << record
      end
    end
  end

  def handle_csv_error(error) # rubocop:disable Lint/UnusedMethodArgument
    @data_import.update!(status: :failed)
    send_import_failed_notification_to_admin
  end

  def send_import_notification_to_admin
    AdministratorNotifications::AccountNotificationMailer.with(account: @data_import.account).contact_import_complete(@data_import).deliver_later
  end

  def send_import_failed_notification_to_admin
    AdministratorNotifications::AccountNotificationMailer.with(account: @data_import.account).contact_import_failed.deliver_later
  end

  def csv_headers
    header_row = nil
    with_import_file do |file|
      header_row = csv_reader(file).first
    end
    header_row&.headers || []
  end

  def csv_reader(file)
    file.rewind
    raw_data = file.read
    utf8_data = raw_data.force_encoding('UTF-8')
    clean_data = utf8_data.valid_encoding? ? utf8_data : utf8_data.encode('UTF-16le', invalid: :replace, replace: '').encode('UTF-8')
    clean_data = clean_data.delete_prefix("\xEF\xBB\xBF")

    CSV.new(StringIO.new(clean_data), headers: true)
  end

  def with_import_file
    temp_dir = Rails.root.join('tmp/imports')
    FileUtils.mkdir_p(temp_dir)

    @data_import.import_file.open(tmpdir: temp_dir) do |file|
      file.binmode
      yield file
    end
  end
end
