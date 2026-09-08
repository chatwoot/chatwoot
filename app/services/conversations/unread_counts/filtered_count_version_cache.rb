class Conversations::UnreadCounts::FilteredCountVersionCache
  attr_reader :account, :user, :store

  def initialize(account:, user:, store:)
    @account = account
    @user = user
    @store = store
  end

  def built_in_filter = { account_version: account_version, built_in_filter_version: built_in_filter_version }

  def folder_index = { folder_index_version: store.folder_index_version(account_id: account.id, user_id: user.id) }

  def filter(filter_id)
    {
      account_version: account_version,
      filter_version: filter_version(filter_id),
      owner_built_in_filter_version: built_in_filter_version
    }
  end

  private

  def account_version = @account_version ||= store.conversation_version(account.id)

  def built_in_filter_version = @built_in_filter_version ||= store.built_in_filter_version(account_id: account.id, user_id: user.id)

  def filter_version(filter_id) = (@filter_versions ||= {})[filter_id] ||= store.filter_version(account_id: account.id, filter_id: filter_id)
end
