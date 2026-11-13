module Enterprise::SearchIndexing::Account
  extend ActiveSupport::Concern

  included do
    after_update_commit :invalidate_disabled_search_indices, if: -> { previous_changes.keys.intersect?(%w[feature_flags feature_flags_ext_1]) }
    after_destroy_commit :purge_search_documents
  end

  private

  def invalidate_disabled_search_indices
    ::SearchIndexing::IndexState.where(account_id: id).find_each do |state|
      state.invalidate! unless ::SearchIndexing::Producer.eligible?(state.entity, self)
    end
  end

  def purge_search_documents
    return unless ChatwootApp.advanced_search_allowed?

    ::SearchIndexing::IndexState.purge_for(id)
  end
end
