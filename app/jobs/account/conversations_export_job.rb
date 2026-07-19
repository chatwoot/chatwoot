class Account::ConversationsExportJob < ApplicationJob
  queue_as :low

  LABELS_COLUMN = 'labels'.freeze
  LABELS_DELIMITER = ','.freeze
  EXPORT_FORMATS = %w[csv xlsx].freeze

  def perform(account_id, user_id, params = {})
    @account = Account.find(account_id)
    @account_user = @account.users.find(user_id)
    @params = params.to_h.with_indifferent_access
    @format = normalize_format(@params[:export_format])

    headers = export_headers
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

  def export_headers
    [
      'display_id', 'url', 'created_at', 'last_activity_at',
      'status', 'status_label', 'assignee', 'team', 'inbox', 'channel',
      'contact_name', 'contact_email', 'contact_phone', 'contact_document_number',
      LABELS_COLUMN
    ] + conversation_attribute_keys + contact_attribute_headers
  end

  def conversation_attribute_keys
    @conversation_attribute_keys ||= @account.custom_attribute_definitions
                                             .conversation_attribute
                                             .order(featured: :desc, attribute_display_name: :asc)
                                             .pluck(:attribute_key)
  end

  def contact_attribute_keys
    @contact_attribute_keys ||= @account.custom_attribute_definitions
                                        .contact_attribute
                                        .order(featured: :desc, attribute_display_name: :asc)
                                        .pluck(:attribute_key)
  end

  def contact_attribute_headers
    contact_attribute_keys.map do |key|
      conversation_attribute_keys.include?(key) ? "contact_#{key}" : key
    end
  end

  def build_rows(headers)
    conversations_to_export.map { |conversation| headers.map { |header| value_for_header(conversation, header) } }
  end

  def value_for_header(conversation, header)
    case header
    when 'display_id' then conversation.display_id
    when 'url' then conversation_url(conversation)
    when 'created_at' then conversation.created_at
    when 'last_activity_at' then conversation.last_activity_at
    when 'status' then conversation.status
    when 'status_label' then status_label(conversation)
    when 'assignee' then conversation.assignee&.name || conversation.assignee_agent_bot&.name
    when 'team' then conversation.team&.name
    when 'inbox' then conversation.inbox&.name
    when 'channel' then conversation.inbox&.channel_type.to_s.delete_prefix('Channel::')
    when 'contact_name' then conversation.contact&.name
    when 'contact_email' then conversation.contact&.email
    when 'contact_phone' then conversation.contact&.phone_number
    when 'contact_document_number' then conversation.contact&.document_number
    when LABELS_COLUMN then conversation_labels_by_id.fetch(conversation.id, []).join(LABELS_DELIMITER)
    else
      custom_attribute_value(conversation, header)
    end
  end

  def custom_attribute_value(conversation, header)
    if conversation_attribute_keys.include?(header)
      return conversation.custom_attributes.to_h[header]
    end

    contact_key = header.start_with?('contact_') ? header.delete_prefix('contact_') : header
    return unless contact_attribute_keys.include?(contact_key)

    conversation.contact&.custom_attributes.to_h[contact_key]
  end

  def status_label(conversation)
    return @account.resolved_status_label_word if conversation.resolved?

    conversation.status
  end

  def conversation_url(conversation)
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{@account.id}/conversations/#{conversation.display_id}"
  end

  def conversations_to_export
    scope = conversations.includes(:assignee, :assignee_agent_bot, :team, :inbox, :contact)
    records = scope.to_a
    preload_conversation_labels(records)
    records
  end

  def conversations
    if @params[:payload].present? && @params[:payload].any?
      filtered_conversations
    elsif list_filters?
      list_filtered_conversations
    else
      Conversations::PermissionFilterService.new(
        @account.conversations,
        @account_user,
        @account
      ).perform
    end
  end

  def filtered_conversations
    result = ::Conversations::FilterService.new(@params, @account_user, @account).perform
    result[:conversations].unscope(:limit, :offset)
  end

  # Reuse ConversationFinder — same query path as ConversationsController#index
  def list_filtered_conversations
    Current.account = @account
    result = ConversationFinder.new(@account_user, list_finder_params).perform
    result[:conversations].unscope(:limit, :offset)
  ensure
    Current.reset
  end

  def list_filters?
    list_finder_params.values.any?(&:present?)
  end

  def list_finder_params
    @params.slice(:inbox_id, :status, :assignee_type, :team_id, :labels, :conversation_type)
  end

  def preload_conversation_labels(records)
    conversation_ids = records.map(&:id)
    return if conversation_ids.blank?

    ActsAsTaggableOn::Tagging
      .joins(:tag)
      .where(context: LABELS_COLUMN, taggable_type: 'Conversation', taggable_id: conversation_ids)
      .where(tags: { name: approved_labels })
      .pluck(:taggable_id, 'tags.name')
      .each { |conversation_id, label| conversation_labels_by_id[conversation_id] << label }
  end

  def approved_labels
    @approved_labels ||= @account.labels.pluck(:title)
  end

  def conversation_labels_by_id
    @conversation_labels_by_id ||= Hash.new { |hash, id| hash[id] = [] }
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
      rows.each { |row| csv << row }
    end
    return if csv_data.blank?

    bom = "\xEF\xBB\xBF"
    @account.conversations_export.attach(
      io: StringIO.new("#{bom}#{csv_data}"),
      filename: export_filename('csv'),
      content_type: 'text/csv'
    )
  end

  def attach_xlsx(headers, rows)
    package = Axlsx::Package.new
    package.workbook.add_worksheet(name: 'Conversations') do |sheet|
      sheet.add_row headers
      rows.each { |row| sheet.add_row row }
    end

    @account.conversations_export.attach(
      io: StringIO.new(package.to_stream.read),
      filename: export_filename('xlsx'),
      content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    )
  end

  def export_filename(extension)
    "#{@account.name}_#{@account.id}_conversations.#{extension}"
  end

  def broadcast_export_completed
    ActionCableBroadcastJob.perform_later(
      [@account_user.pubsub_token],
      'export.completed',
      {
        account_id: @account.id,
        resource: 'conversations',
        format: @format,
        download_url: export_file_url
      }
    )
  end

  def send_mail
    mailer = AdministratorNotifications::AccountNotificationMailer.with(account: @account)
    mailer.conversation_export_complete(export_file_url, @account_user.email)&.deliver_later
  end

  def export_file_url
    Rails.application.routes.url_helpers.rails_blob_url(@account.conversations_export)
  end
end
