class DataImports::Intercom::CredentialsValidator
  def initialize(access_token:, import_types:)
    @access_token = access_token.to_s.strip
    @import_types = Array(import_types).compact_blank
  end

  def perform
    validate_parameters!

    {}.tap do |totals|
      contacts_response = client.list_contacts(per_page: 1) if @import_types.intersect?(%w[contacts conversations])
      totals['contacts'] = total_count(contacts_response) if @import_types.include?('contacts')
      totals['conversations'] = total_count(client.list_conversations(per_page: 1)) if @import_types.include?('conversations')
    end.compact
  end

  private

  def validate_parameters!
    raise ArgumentError, 'Intercom access key is required.' if @access_token.blank?
    raise ArgumentError, 'Select at least one data type to import.' if @import_types.blank?

    invalid_types = @import_types - DataImport::IMPORT_TYPES
    return if invalid_types.blank?

    raise ArgumentError, "Unsupported import types: #{invalid_types.join(', ')}"
  end

  def client
    @client ||= DataImports::Intercom::Client.new(access_token: @access_token)
  end

  def total_count(response)
    response['total_count'] if response.key?('total_count')
  end
end
