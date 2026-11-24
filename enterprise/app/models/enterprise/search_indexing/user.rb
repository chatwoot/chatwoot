module Enterprise::SearchIndexing::User
  extend ActiveSupport::Concern

  included do
    after_destroy_commit :refresh_search_after_user_removal
  end

  private

  def refresh_search_after_user_removal
    return unless ChatwootApp.advanced_search_allowed?

    ::SearchIndexing::AssociationRefreshJob.perform_later('assignee_id', id)
  end
end
