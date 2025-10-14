class V2::Reports::Conversations::ConversationsAggregator < V2::Reports::Conversations::BaseAggregator
  private

  def compute_metrics
    {
      conversations_count: base_relation.count
    }
  end

  def base_relation
    scope.conversations
         .where(account_id: account.id, created_at: range)
         .unscope(:order)
         .reorder(nil)
  end
end
