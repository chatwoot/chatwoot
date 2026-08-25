class DataImports::Freshdesk::CredentialsValidator
  def initialize(domain:, api_key:, import_types:)
    @domain = domain
    @api_key = api_key.to_s.strip
    @import_types = Array(import_types).compact_blank
  end

  def perform
    validate_parameters!
    client.list_contacts(per_page: 1) if @import_types.include?('contacts')
    client.list_tickets(per_page: 1) if @import_types.include?('conversations')
    {}
  end

  private

  def validate_parameters!
    raise ArgumentError, 'Freshdesk domain is required.' if @domain.blank?
    raise ArgumentError, 'Freshdesk API key is required.' if @api_key.blank?
    raise ArgumentError, 'Select at least one data type to import.' if @import_types.blank?

    invalid_types = @import_types - DataImport::IMPORT_TYPES
    raise ArgumentError, "Unsupported import types: #{invalid_types.join(', ')}" if invalid_types.present?

    DataImports::Freshdesk::Client.normalize_domain(@domain)
  end

  def client
    @client ||= DataImports::Freshdesk::Client.new(domain: @domain, api_key: @api_key)
  end
end
