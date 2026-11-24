class SearchIndexing::IndexVerification
  KEY = 'conversation_search_verification'.freeze

  def self.identity
    name = Conversation.search_index.name
    settings = Searchkick.client.indices.get_settings(index: name, name: 'index.uuid')
    { 'name' => name, 'uuid' => settings.fetch(name).fetch('settings').fetch('index').fetch('uuid') }
  end

  def self.ready?(account, version: 1)
    return false unless SearchIndexing::Conversations.enabled?(account)

    verification = account.internal_attributes[KEY]
    verification.present? && verification.fetch('version') >= version && verification.fetch('index') == identity
  end

  def self.record!(account, index_identity, account_updated_at:)
    return false unless identity == index_identity

    account.with_lock do
      return false unless SearchIndexing::Conversations.enabled?(account) && account.updated_at == account_updated_at

      value = { 'index' => index_identity, 'version' => SearchIndexing::ConversationDocument::VERSION, 'verified_at' => Time.current.iso8601 }
      account.update!(internal_attributes: account.internal_attributes.merge(KEY => value))
    end
    true
  end

  def self.clear!(account)
    account.with_lock { account.update!(internal_attributes: account.internal_attributes.except(KEY)) }
  end
end
