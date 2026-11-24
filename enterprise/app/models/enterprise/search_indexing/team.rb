module Enterprise::SearchIndexing::Team
  extend ActiveSupport::Concern

  included do
    after_destroy_commit :refresh_search_after_team_removal
  end

  private

  def refresh_search_after_team_removal
    return unless ChatwootApp.advanced_search_allowed?

    ::SearchIndexing::AssociationRefreshJob.perform_later('team_id', id, account_id)
  end
end
