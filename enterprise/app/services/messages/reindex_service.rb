class Messages::ReindexService
  pattr_initialize [:account!]

  def perform
    return unless searchkick_enabled?

    reindex_messages
  end

  private

  def searchkick_enabled?
    ENV['OPENSEARCH_URL'].present?
  end

  def reindex_messages
    account.messages.reindex(mode: :async)
  end
end
