class DataImports::Freshdesk::PlaceholderInboxBuilder < DataImports::PlaceholderInboxBuilder
  def initialize(account:)
    super(account: account, provider: 'freshdesk', source_bucket: DataImports::Freshdesk::SourceBucket)
  end
end
