module Enterprise::SearchIndexing::AiAssignee
  extend ActiveSupport::Concern

  included do
    after_destroy_commit :refresh_search_after_ai_assignee_removal
  end

  private

  def refresh_search_after_ai_assignee_removal
    return unless ChatwootApp.advanced_search_allowed?

    ::SearchIndexing::AssociationRefreshJob.perform_later('assignee_agent_bot_id', id, account_id)
  end
end
