class DataImports::Source
  PROVIDERS = {
    'freshdesk' => 'DataImports::Freshdesk::Source',
    'intercom' => 'DataImports::Intercom::Source'
  }.freeze

  def self.for(data_import)
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
end
