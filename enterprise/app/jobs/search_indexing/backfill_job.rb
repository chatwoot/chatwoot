class SearchIndexing::BackfillJob < ApplicationJob
  queue_as :search_backfill

  def perform(state_id, run_token)
    return unless ChatwootApp.advanced_search_allowed?

    state = SearchIndexing::IndexState.find_by(id: state_id)
    return unless state

    ActiveRecord::Base.connected_to(role: :writing) do
      state.with_lock do
        return unless state.run_token == run_token && state.status == 'running'

        SearchIndexing::Backfill.new(state).perform
        state.update!(run_token: SecureRandom.hex(16)) if state.status == 'running'
      end
    end
    self.class.set(wait: 30.seconds).perform_later(state.id, state.run_token) if state.status == 'running'
  end
end
