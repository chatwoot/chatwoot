class DataImports::Intercom::Source
  PROVIDER = 'intercom'.freeze
  DISPLAY_NAME = 'Intercom'.freeze
  CONTACTS_PER_PAGE = 50
  CONVERSATIONS_PER_PAGE = 10
  ALREADY_IMPORTED_ERROR_CODE = 'DataImports::Intercom::AlreadyImported'.freeze
  SKIPPED_MESSAGE_ERROR_CODE = 'DataImports::Intercom::SkippedMessage'.freeze
  TRUNCATED_PARTS_ERROR_CODE = 'DataImports::Intercom::TruncatedConversationParts'.freeze

  attr_reader :provider, :display_name, :contacts_per_page, :conversations_per_page

  def self.credentials_validator(source_params:, import_types:)
    DataImports::Intercom::CredentialsValidator.new(
      access_token: source_params[:access_token],
      import_types: import_types
    )
  end

  def self.source_metadata(_source_params)
    {}
  end

  def self.default_import_name
    'Intercom import'
  end

  def self.credential_name
    'access key'
  end

  def self.import_job_class
    DataImports::Intercom::ImportJob
  end

  def self.importer_class
    DataImports::Intercom::Importer
  end

  def self.contacts_page_job_class
    DataImports::Intercom::ContactsPageJob
  end

  def self.conversations_page_job_class
    DataImports::Intercom::ConversationsPageJob
  end

  def self.client_error?(error)
    error.is_a?(DataImports::Intercom::Client::Error)
  end

  def self.authentication_error?(error)
    error.is_a?(DataImports::Intercom::Client::AuthenticationError)
  end

  def initialize(access_token:, source_metadata: {}) # rubocop:disable Lint/UnusedMethodArgument
    @provider = PROVIDER
    @display_name = DISPLAY_NAME
    @contacts_per_page = CONTACTS_PER_PAGE
    @conversations_per_page = CONVERSATIONS_PER_PAGE
    @client = DataImports::Intercom::Client.new(access_token: access_token)
  end

  def list_contacts(starting_after:, per_page:)
    @client.list_contacts(starting_after: starting_after, per_page: per_page)
  end

  def list_conversations(starting_after:, per_page:)
    @client.list_conversations(starting_after: starting_after, per_page: per_page)
  end

  def retrieve_conversation(id)
    @client.retrieve_conversation(id)
  end

  def retrieve_contact(id)
    @client.retrieve_contact(id)
  end

  def client_error?(error)
    error.is_a?(DataImports::Intercom::Client::Error)
  end

  def placeholder_inbox_builder(account:)
    DataImports::Intercom::PlaceholderInboxBuilder.new(account: account)
  end

  def message_batch_builder(data_import:, conversation:, source_conversation:)
    DataImports::Intercom::MessageBatchBuilder.new(
      data_import: data_import,
      conversation: conversation,
      source_conversation: source_conversation
    )
  end

  def activity_part?(part)
    DataImports::Intercom::MessageBatchBuilder.activity_part?(part)
  end

  def source_message_importable?(source)
    DataImports::Intercom::MessageBatchBuilder.source_message_importable?(source)
  end

  def activity_content(part)
    DataImports::Intercom::ActivityContentBuilder.new(part).perform
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
    'blank_or_unsupported_intercom_part'
  end

  def contact_custom_attributes(contact_payload)
    {
      intercom_contact_id: contact_payload['id'],
      intercom_external_id: contact_payload['external_id']
    }.compact
  end

  def contact_source_metadata(contact_payload)
    {
      contact_id: contact_payload['id'],
      external_id: contact_payload['external_id'],
      raw_phone: contact_payload['phone']
    }.compact
  end

  def conversation_custom_attributes(conversation)
    { intercom_conversation_id: source_id_for(conversation) }
  end

  def conversation_source_metadata(conversation)
    {
      conversation_id: source_id_for(conversation),
      delivered_as: conversation.dig('source', 'delivered_as'),
      source_url: conversation.dig('source', 'url'),
      admin_assignee_id: conversation['admin_assignee_id'],
      team_assignee_id: conversation['team_assignee_id'],
      state: conversation['state'],
      open: conversation['open']
    }.compact
  end

  def message_source_metadata(part)
    {
      part_id: part['id'],
      part_type: part['part_type'],
      author: part['author'],
      assigned_to: part['assigned_to'],
      state: part['state'],
      tags: part['tags'],
      event_details: part['event_details'],
      app_package_code: part['app_package_code'],
      metadata: part['metadata'],
      attachments: part['attachments'],
      redacted: part['redacted']
    }.compact
  end

  def timestamp_for(value)
    return Time.current if value.blank?

    Time.zone.at(value.to_i)
  end

  private

  def source_id_for(payload)
    payload['id'].presence || payload['external_id'].presence || payload['email'].presence
  end
end
