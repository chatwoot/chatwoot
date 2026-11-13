class ReplaceRetiredCaptainModels < ActiveRecord::Migration[7.2]
  # Runs inline because a queued job can reach Sidekiq workers still on the previous release, which don't have the job class yet.
  def up
    Migration::ReplaceRetiredCaptainModelsJob.perform_now
  end

  def down; end
end
