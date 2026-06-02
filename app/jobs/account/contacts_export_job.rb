class Account::ContactsExportJob < ApplicationJob
  queue_as :low

  LABELS_COLUMN = 'labels'.freeze
  LABELS_DELIMITER = ','.freeze

  def perform(account_id, user_id, column_names, params)
    @account = Account.find(account_id)
    @params = params
    @account_user = @account.users.find(user_id)

    headers = valid_headers(column_names)
    generate_csv(headers)
    send_mail
  end

  private

  def generate_csv(headers)
    contacts_to_export = contacts.to_a
    preload_contact_labels(contacts_to_export) if headers.include?(LABELS_COLUMN)

    csv_data = CSV.generate do |csv|
      csv << headers
      contacts_to_export.each do |contact|
        csv << headers.map { |header| value_for_header(contact, header) }
      end
    end

    attach_export_file(csv_data)
  end

  def value_for_header(contact, header)
    return contact_labels_by_id.fetch(contact.id, []).join(LABELS_DELIMITER) if header == LABELS_COLUMN

    contact.send(header)
  end

  def approved_labels
    @approved_labels ||= @account.labels.pluck(:title)
  end

  def preload_contact_labels(contacts_to_export)
    contact_ids = contacts_to_export.map(&:id)
    return if contact_ids.blank?

    ActsAsTaggableOn::Tagging
      .joins(:tag)
      .where(context: LABELS_COLUMN, taggable_type: 'Contact', taggable_id: contact_ids)
      .where(tags: { name: approved_labels })
      .pluck(:taggable_id, 'tags.name')
      .each { |contact_id, label| contact_labels_by_id[contact_id] << label }
  end

  def contact_labels_by_id
    @contact_labels_by_id ||= Hash.new { |hash, contact_id| hash[contact_id] = [] }
  end

  def contacts
    if @params.present? && @params[:payload].present? && @params[:payload].any?
      result = ::Contacts::FilterService.new(@account, @account_user, @params).perform
      result[:contacts]
    elsif @params[:label].present?
      @account.contacts.resolved_contacts(use_crm_v2: @account.feature_enabled?('crm_v2')).tagged_with(@params[:label], any: true)
    else
      @account.contacts.resolved_contacts(use_crm_v2: @account.feature_enabled?('crm_v2'))
    end
  end

  def valid_headers(column_names)
    requested_headers = column_names.presence || default_columns

    # Keep requested header order while allowing the virtual labels column.
    requested_headers.select do |header|
      header == LABELS_COLUMN || Contact.column_names.include?(header)
    end.uniq
  end

  def attach_export_file(csv_data)
    return if csv_data.blank?

    # Prepend UTF-8 BOM so that spreadsheet applications (e.g. Excel)
    # correctly recognise the file encoding for non-ASCII characters
    # such as Arabic, Japanese, and Chinese.
    bom = "\xEF\xBB\xBF"

    @account.contacts_export.attach(
      io: StringIO.new("#{bom}#{csv_data}"),
      filename: "#{@account.name}_#{@account.id}_contacts.csv",
      content_type: 'text/csv'
    )
  end

  def send_mail
    file_url = account_contact_export_url
    mailer = AdministratorNotifications::AccountNotificationMailer.with(account: @account)
    mailer.contact_export_complete(file_url, @account_user.email)&.deliver_later
  end

  def account_contact_export_url
    Rails.application.routes.url_helpers.rails_blob_url(@account.contacts_export)
  end

  def default_columns
    %w[id name email phone_number labels]
  end
end
