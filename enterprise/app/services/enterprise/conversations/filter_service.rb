module Enterprise::Conversations::FilterService
  private

  def indexed_filter_result
    result = ::SearchIndexing::ConversationFilter.new(@account, @user, @params).perform
    return unless result

    records = @conversations.in_order_of(:id, result.fetch(:ids)).to_a
    # A changed/deleted row must not produce a short page with an unrelated engine count.
    return unless records.size == result.fetch(:ids).size

    Rails.logger.info("Conversation filters backend=opensearch account_id=#{@account.id} total=#{result.fetch(:count).fetch(:all_count)}")
    { conversations: records, count: result.fetch(:count) }
  end
end
