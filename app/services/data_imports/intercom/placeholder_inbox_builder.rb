class DataImports::Intercom::PlaceholderInboxBuilder < DataImports::PlaceholderInboxBuilder
  def initialize(account:)
    super(account: account, provider: 'intercom', source_bucket: DataImports::Intercom::SourceBucket)
  end
end
