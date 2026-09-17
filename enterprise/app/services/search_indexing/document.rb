class SearchIndexing::Document
  attr_reader :account_id

  def initialize(account_id)
    @account_id = account_id
  end

  def index_name(epoch)
    "chatwoot_#{Rails.env}_#{self.class::ENTITY}_#{self.class::SCHEMA_VERSION}_#{epoch}"
  end

  def ensure_index!(epoch)
    return if Searchkick.client.indices.exists?(index: index_name(epoch))

    SearchIndexing::IndexState.invalidate_index!(self.class::ENTITY, epoch)
    Searchkick.client.indices.create(index: index_name(epoch), body: mapping)
  rescue OpenSearch::Transport::Transport::Errors::BadRequest => e
    raise unless e.message.include?('resource_already_exists_exception')
  end

  def mapping
    {
      mappings: { dynamic: false, properties: properties.merge(account_id: { type: 'long' }, deleted: { type: 'boolean' }) }
    }
  end
end
