class Account::ContactsExportJob < ApplicationJob
  queue_as :low

  LABELS_COLUMN = 'labels'.freeze
  ASSIGNED_AGENT_COLUMN = 'assigned_agent'.freeze
  VIRTUAL_COLUMNS = %w[assigned_agent company_name city country].freeze
  # Force spreadsheet apps to treat these as text (avoid scientific notation).
  TEXT_FORCE_HEADERS = %w[phone_number document_number identifier contact_phone contact_document_number].freeze
  LABELS_DELIMITER = ','.freeze
  EXPORT_FORMATS = %w[csv xlsx].freeze

  def perform(account_id, user_id, column_names, params)
    @account = Account.find(account_id)
    @params = (params || {}).to_h.with_indifferent_access
    @account_user = @account.users.find(user_id)
    @format = normalize_format(@params[:export_format])

    headers = valid_headers(column_names)
    rows = build_rows(headers)
    attach_export_file(headers, rows)
    broadcast_export_completed
    send_mail
  end

  private

  def normalize_format(value)
    format = value.to_s.downcase
    EXPORT_FORMATS.include?(format) ? format : 'csv'
  end

  def build_rows(headers)
    contacts_to_export = contacts.to_a
    preload_contact_labels(contacts_to_export) if headers.include?(LABELS_COLUMN)
    ActiveRecord::Associations::Preloader.new(records: contacts_to_export, associations: :assigned_agent).call if headers.include?(ASSIGNED_AGENT_COLUMN)

    contacts_to_export.map { |contact| headers.map { |header| value_for_header(contact, header) } }
  end

  def value_for_header(contact, header)
    return contact_labels_by_id.fetch(contact.id, []).join(LABELS_DELIMITER) if header == LABELS_COLUMN
    return assigned_agent_name(contact) if header == ASSIGNED_AGENT_COLUMN
    return additional_attribute(contact, 'company_name') if header == 'company_name'
    return additional_attribute(contact, 'city') if header == 'city'
    return country_value(contact) if header == 'country'
    return contact.custom_attributes.to_h[header] if contact_custom_attribute_keys.include?(header)

    contact.send(header)
  end

  def force_text_header?(header)
    TEXT_FORCE_HEADERS.include?(header)
  end

  # Leading tab keeps Excel/Sheets from coercing long digit strings to numbers in CSV.
  def spreadsheet_text(value)
    return '' if value.nil?

    text = value.to_s
    return '' if text.blank?

    "\t#{text}"
  end

  def assigned_agent_name(contact)
    agent = contact.assigned_agent
    return '' unless agent

    agent.try(:available_name).presence || agent.name
  end

  def additional_attribute(contact, key)
    contact.additional_attributes.to_h[key].to_s
  end

  def country_value(contact)
    attrs = contact.additional_attributes.to_h
    attrs['country'].presence || attrs['country_code'].presence || contact.country_code.to_s
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

    # Keep requested header order while allowing labels, virtual columns, and contact custom attributes.
    requested_headers.select do |header|
      header == LABELS_COLUMN ||
        VIRTUAL_COLUMNS.include?(header) ||
        Contact.column_names.include?(header) ||
        contact_custom_attribute_keys.include?(header)
    end.uniq
  end

  def contact_custom_attribute_keys
    @contact_custom_attribute_keys ||= @account.custom_attribute_definitions
                                               .contact_attribute
                                               .order(featured: :desc, attribute_display_name: :asc)
                                               .pluck(:attribute_key)
  end

  def attach_export_file(headers, rows)
    if @format == 'xlsx'
      attach_xlsx(headers, rows)
    else
      attach_csv(headers, rows)
    end
  end

  def attach_csv(headers, rows)
    csv_data = CSV.generate do |csv|
      csv << headers
      rows.each do |row|
        csv << row.map.with_index do |cell, index|
          force_text_header?(headers[index]) ? spreadsheet_text(cell) : cell
        end
      end
    end
    return if csv_data.blank?

    # Prepend UTF-8 BOM so that spreadsheet applications (e.g. Excel)
    # correctly recognise the file encoding for non-ASCII characters
    # such as Arabic, Japanese, and Chinese.
    bom = "\xEF\xBB\xBF"

    @account.contacts_export.attach(
      io: StringIO.new("#{bom}#{csv_data}"),
      filename: export_filename('csv'),
      content_type: 'text/csv'
    )
  end

  def attach_xlsx(headers, rows)
    package = Axlsx::Package.new
    package.workbook.add_worksheet(name: 'Contacts') do |sheet|
      types = headers.map { |header| force_text_header?(header) ? :string : nil }
      sheet.add_row headers
      rows.each do |row|
        cells = row.map { |cell| cell.nil? ? '' : cell }
        sheet.add_row cells, types: types
      end
    end

    @account.contacts_export.attach(
      io: StringIO.new(package.to_stream.read),
      filename: export_filename('xlsx'),
      content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    )
  end

  def export_filename(extension)
    "#{@account.name}_#{@account.id}_contacts.#{extension}"
  end

  def broadcast_export_completed
    ActionCableBroadcastJob.perform_later(
      [@account_user.pubsub_token],
      'export.completed',
      {
        account_id: @account.id,
        resource: 'contacts',
        format: @format,
        download_url: account_contact_export_url
      }
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
    %w[id name email document_number phone_number labels] + contact_custom_attribute_keys
  end
end
