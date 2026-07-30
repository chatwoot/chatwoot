class DataImports::Freshdesk::Source
  PROVIDER = 'freshdesk'.freeze
  DISPLAY_NAME = 'Freshdesk'.freeze
  CONTACTS_PER_PAGE = 100
  CONVERSATIONS_PER_PAGE = 100
  ALREADY_IMPORTED_ERROR_CODE = 'DataImports::Freshdesk::AlreadyImported'.freeze
  SKIPPED_MESSAGE_ERROR_CODE = 'DataImports::Freshdesk::SkippedMessage'.freeze
  TRUNCATED_PARTS_ERROR_CODE = 'DataImports::Freshdesk::TruncatedConversations'.freeze

  attr_reader :provider, :display_name, :contacts_per_page, :conversations_per_page

  def self.credentials_validator(source_params:, import_types:)
    DataImports::Freshdesk::CredentialsValidator.new(
      domain: source_params[:domain],
      api_key: source_params[:access_token],
      import_types: import_types
    )
  end

  def self.source_metadata(source_params)
    { domain: DataImports::Freshdesk::Client.normalize_domain(source_params[:domain]) }
  end

  def self.default_import_name
    'Freshdesk import'
  end

  def self.credential_name
    'API key'
  end

  def self.import_job_class
    DataImports::Freshdesk::ImportJob
  end

  def self.importer_class
    DataImports::Freshdesk::Importer
  end

  def self.contacts_page_job_class
    DataImports::Freshdesk::ContactsPageJob
  end

  def self.conversations_page_job_class
    DataImports::Freshdesk::ConversationsPageJob
  end

  def self.client_error?(error)
    error.is_a?(DataImports::Freshdesk::Client::Error)
  end

  def self.authentication_error?(error)
    error.is_a?(DataImports::Freshdesk::Client::AuthenticationError)
  end

  def initialize(access_token:, source_metadata: {})
    @provider = PROVIDER
    @display_name = DISPLAY_NAME
    @contacts_per_page = CONTACTS_PER_PAGE
    @conversations_per_page = CONVERSATIONS_PER_PAGE
    @client = DataImports::Freshdesk::Client.new(domain: source_metadata['domain'] || source_metadata[:domain], api_key: access_token)
    @normalizer = DataImports::Freshdesk::Normalizer.new
    @metadata = DataImports::Freshdesk::Metadata.new
  end

  def list_contacts(starting_after:, per_page:)
    page = @client.list_contacts(page: starting_after.presence || 1, per_page: per_page)
    paginated_response(page, Array(page.data).map { |contact| @normalizer.contact(contact) })
  end

  def list_conversations(starting_after:, per_page:)
    page = DataImports::Freshdesk::TicketPage.new(client: @client, starting_after: starting_after, per_page: per_page)
    summaries = page.chunk.map do |ticket|
      {
        'id' => ticket['id'].to_s,
        'source' => { 'type' => DataImports::Freshdesk::SourceBucket.source_type(ticket['source']) }
      }
    end
    {
      'data' => summaries,
      'pages' => {
        'current' => { 'starting_after' => page.current_cursor },
        'next' => page.next_cursor.present? ? { 'starting_after' => page.next_cursor } : nil,
        'checkpoints' => page.checkpoints,
        'limit_reached' => page.limit_reached?
      }
    }
  end

  def retrieve_conversation(id)
    ticket = @client.retrieve_ticket(id)
    conversations = all_conversations(id)
    @normalizer.ticket(ticket, conversations)
  end

  def retrieve_contact(id)
    @normalizer.contact(@client.retrieve_contact(id))
  end

  def client_error?(error)
    error.is_a?(DataImports::Freshdesk::Client::Error)
  end

  def placeholder_inbox_builder(account:)
    DataImports::Freshdesk::PlaceholderInboxBuilder.new(account: account)
  end

  def message_batch_builder(data_import:, conversation:, source_conversation:)
    DataImports::Freshdesk::MessageBatchBuilder.new(
      data_import: data_import,
      conversation: conversation,
      source_conversation: source_conversation
    )
  end

  def activity_part?(_part)
    false
  end

  def source_message_importable?(source)
    DataImports::Freshdesk::MessageBatchBuilder.source_message_importable?(source)
  end

  def activity_content(_part)
    nil
  end

  def already_imported_error_code
    ALREADY_IMPORTED_ERROR_CODE
  end

  def skipped_message_error_code
    SKIPPED_MESSAGE_ERROR_CODE
  end

  def truncated_parts_error_code
    TRUNCATED_PARTS_ERROR_CODE
  end

  def skipped_message_reason
    'blank_freshdesk_conversation'
  end

  def contact_custom_attributes(contact_payload)
    @metadata.contact_custom_attributes(contact_payload)
  end

  def contact_source_metadata(contact_payload)
    @metadata.contact_source(contact_payload)
  end

  def conversation_custom_attributes(conversation)
    {
      freshdesk_ticket_id: conversation['id'],
      freshdesk_subject: conversation['subject'],
      freshdesk_status: conversation['status'],
      freshdesk_priority: conversation['priority']
    }.compact
  end

  def conversation_source_metadata(conversation)
    @metadata.conversation_source(conversation)
  end

  def message_source_metadata(part)
    @metadata.message_source(part)
  end

  def timestamp_for(value)
    return Time.current if value.blank?

    value.is_a?(Numeric) || value.to_s.match?(/\A-?\d+(?:\.\d+)?\z/) ? Time.zone.at(value.to_f) : Time.zone.parse(value.to_s)
  end

  private

  def paginated_response(page, records)
    {
      'data' => records,
      'pages' => { 'next' => page.next_page.present? ? { 'starting_after' => page.next_page } : nil }
    }
  end

  def all_conversations(ticket_id)
    records = []
    page_number = 1
    loop do
      page = @client.list_conversations(ticket_id, page: page_number, per_page: CONVERSATIONS_PER_PAGE)
      records.concat(Array(page.data))
      break if page.next_page.blank?

      page_number = page.next_page
    end
    records
  end
end
