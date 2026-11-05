# TODO: logic is written tailored to contact import since its the only import available
# let's break this logic and clean this up in future

class DataImportJob < ApplicationJob
  queue_as :low
  retry_on ActiveStorage::FileNotFoundError, wait: 1.minute, attempts: 3

  BATCH_SIZE = 1000
  LABELS_DELIMITER = ','.freeze
  LABELS_CONTEXT = 'labels'.freeze
  CONTACT_TAGGABLE_TYPE = 'Contact'.freeze

  def perform(data_import)
    @data_import = data_import
    @contact_manager = DataImport::ContactManager.new(@data_import.account)
    catch(:inactive_import) do
      process_import_file
      send_import_notification_to_admin
    rescue CSV::MalformedCSVError => e
      handle_csv_error(e)
    end
  end

  private

  # Legacy rows can be abandoned after a lost job. Fence each write batch against a delayed delivery.
  def while_active
    @data_import.with_lock do
      throw :inactive_import unless @data_import.pending? || @data_import.processing?

      yield
    end
  end

  def process_import_file
    while_active { @data_import.update!(status: :processing) }
    contacts, rejected_contacts = parse_csv_and_build_contacts

    contacts.each_slice(BATCH_SIZE) do |batch|
      while_active do
        import_contacts(batch)
        @data_import.update!(updated_at: Time.current)
      end
    end
    save_failed_records_csv(rejected_contacts)
    while_active { update_data_import_status(contacts.length, rejected_contacts.length) }
  end

  def parse_csv_and_build_contacts
    contacts = []
    rejected_contacts = []

    with_import_file do |file|
      csv_reader(file).each_slice(BATCH_SIZE) do |rows|
        while_active do
          rows.each { |row| build_contact_from_row(row, contacts, rejected_contacts) }
          @data_import.update!(updated_at: Time.current)
        end
      end
    end

    [contacts, rejected_contacts]
  end

  def build_contact_from_row(row, contacts, rejected_contacts)
    row_hash = row.to_h.with_indifferent_access
    labels = extract_labels(row_hash)
    invalid_labels = labels.map(&:downcase) - approved_labels

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
    row_hash[:labels].to_s.split(LABELS_DELIMITER).map(&:strip).reject(&:blank?)
  end

  def append_rejected_contact(row, contact, rejected_contacts)
    row['errors'] = contact.errors.full_messages.join(', ')
    rejected_contacts << row
  end

  def import_contacts(contacts_with_labels)
    contacts = contacts_with_labels.pluck(:contact)
    # <struct ActiveRecord::Import::Result failed_instances=[], num_inserts=1, ids=[444, 445], results=[]>
    Contact.import(contacts, synchronize: contacts, on_duplicate_key_ignore: true,
                             track_validation_failures: true, validate: true, batch_size: BATCH_SIZE)
    apply_labels_to_contacts(contacts_with_labels)
  end

  def apply_labels_to_contacts(contacts_with_labels)
    taggings = taggings_for_contacts(contacts_with_labels)
    return if taggings.blank?

    ActsAsTaggableOn::Tagging.import(%i[tag_id taggable_type taggable_id context created_at],
                                     taggings, on_duplicate_key_ignore: true, validate: false, batch_size: BATCH_SIZE)
  end

  def taggings_for_contacts(contacts_with_labels)
    tag_lookup = tags_by_label_name(contacts_with_labels)
    taggings = contacts_with_labels.flat_map do |item|
      contact = contact_for_label_import(item[:contact])
      labels = item[:labels].map(&:downcase).uniq
      next [] if contact&.id.blank?

      labels.map do |label|
        [tag_lookup[label].id, CONTACT_TAGGABLE_TYPE, contact.id, LABELS_CONTEXT]
      end
    end.uniq

    reject_existing_taggings(taggings).map { |tagging| tagging + [Time.zone.now] }
  end

  def reject_existing_taggings(taggings)
    tag_ids = taggings.map { |tag_id, _taggable_type, _taggable_id, _context| tag_id }
    taggable_ids = taggings.map { |_tag_id, _taggable_type, taggable_id, _context| taggable_id }
    existing_taggings = ActsAsTaggableOn::Tagging
                        .where(context: LABELS_CONTEXT, taggable_type: CONTACT_TAGGABLE_TYPE,
                               taggable_id: taggable_ids, tag_id: tag_ids)
                        .pluck(:tag_id, :taggable_id)
                        .index_with(true)

    taggings.reject do |tag_id, _taggable_type, taggable_id, _context|
      existing_taggings[[tag_id, taggable_id]]
    end
  end

  def contact_for_label_import(contact)
    return contact if contact.id.present?

    return @data_import.account.contacts.find_by(identifier: contact.identifier) if contact.identifier.present?
    return @data_import.account.contacts.from_email(contact.email) if contact.email.present?

    @data_import.account.contacts.find_by(phone_number: contact.phone_number) if contact.phone_number.present?
  end

  def tags_by_label_name(contacts_with_labels)
    labels = contacts_with_labels.flat_map { |item| item[:labels] }.map(&:downcase).uniq

    ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name(labels).index_by { |tag| tag.name.downcase }
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
    while_active { @data_import.update!(status: :failed) }
    send_import_failed_notification_to_admin
  end

  def send_import_notification_to_admin
    AdministratorNotifications::AccountNotificationMailer.with(account: @data_import.account).contact_import_complete(@data_import).deliver_later
  end

  def send_import_failed_notification_to_admin
    AdministratorNotifications::AccountNotificationMailer.with(account: @data_import.account).contact_import_failed.deliver_later
  end

  def csv_headers
    with_import_file { |file| csv_reader(file).first&.headers || [] }
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
