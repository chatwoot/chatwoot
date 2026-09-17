class DataImports::Source
  PROVIDERS = {
    'csv' => 'DataImports::Csv::Source',
    'freshdesk' => 'DataImports::Freshdesk::Source',
    'intercom' => 'DataImports::Intercom::Source'
  }.freeze

  def self.for(data_import)
    return source_class('csv').new(data_import: data_import) if data_import.csv_import?

    source_class(data_import.source_provider).new(
      access_token: data_import.access_token,
      source_metadata: data_import.source_metadata
    )
  end

  def self.source_class(provider)
    PROVIDERS.fetch(provider.to_s) { raise ArgumentError, 'Unsupported import source.' }.constantize
  end

  def self.supported?(provider)
    PROVIDERS.key?(provider.to_s)
  end

  def self.import_types(provider)
    provider == 'csv' ? ['contacts'] : DataImports::Importer::DEFAULT_IMPORT_TYPES
  end

  def self.validate_source(provider, params, import_types)
    supported_types = self.import_types(provider)
    unless import_types.is_a?(Array) && import_types.any? && (import_types - supported_types).empty? && import_types.uniq == import_types
      raise ArgumentError, invalid_types_message(import_types, supported_types)
    end

    return DataImports::Csv::UploadValidator.new(params[:import_file]).perform if provider == 'csv'

    source_class(provider).credentials_validator(source_params: params, import_types: import_types).perform
  end

  def self.invalid_types_message(import_types, supported_types)
    invalid_types = import_types.is_a?(Array) ? import_types - supported_types : []
    invalid_types.any? ? "Unsupported import types: #{invalid_types.join(', ')}" : 'Unsupported import types.'
  end
  private_class_method :invalid_types_message
end
