module Enterprise::SearchIndexing::AiAssignee
  extend ActiveSupport::Concern

  included do
    before_destroy :capture_ai_assignee_search_accounts, prepend: true
    after_destroy_commit :refresh_search_after_ai_assignee_removal
  end

  private

  def capture_ai_assignee_search_accounts
    return unless ChatwootApp.advanced_search_allowed?

    @conversation_search_account_ids = account_id ? [account_id] : assigned_conversations.distinct.pluck(:account_id)
  end

  def refresh_search_after_ai_assignee_removal
    return unless ChatwootApp.advanced_search_allowed?

    @conversation_search_account_ids.each do |account_id|
      ::SearchIndexing::AssociationRefreshJob.perform_later('assignee_agent_bot_id', id, account_id)
    end
  end
end
