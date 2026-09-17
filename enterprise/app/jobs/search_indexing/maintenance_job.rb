class SearchIndexing::MaintenanceJob < ApplicationJob
  queue_as :search_backfill

  def perform
    return unless ChatwootApp.advanced_search_allowed?

    recover_interrupted_runs
    SearchIndexing::IndexState.where(status: 'ready').where(updated_at: ...1.day.ago).order(:updated_at).limit(5).each do |state|
      reconcile(state)
    end
  end

  private

  def recover_interrupted_runs
    SearchIndexing::IndexState.where(status: 'running').where(updated_at: ...2.minutes.ago).order(:updated_at).limit(25).each do |state|
      state.with_lock do
        next unless state.status == 'running' && state.updated_at < 2.minutes.ago

        SearchIndexing::BackfillJob.perform_later(state.id, state.run_token)
        state.update!(updated_at: Time.current)
      end
    end
  end

  def reconcile(state)
    if state.account && SearchIndexing::Producer.eligible?(state.entity, state.account)
      SearchIndexing::Backfill.start(account: state.account, entity: state.entity, reconcile: true)
    elsif state.account
      state.invalidate!
    else
      state.update!(status: 'running', phase: 'verify_index', cursor: 0, ready_at: nil)
      SearchIndexing::BackfillJob.perform_later(state.id, state.run_token)
    end
  end
end
