class ReplaceRetiredGptFiveCaptainModels < ActiveRecord::Migration[7.2]
  # Runs the job again for the GPT-5 and o3 models that OpenAI shuts down on December 11, 2026.
  # Runs inline because a queued job can reach Sidekiq workers still on the previous release, which don't have the job class yet.
  def up
    Migration::ReplaceRetiredCaptainModelsJob.perform_now
  end

  def down; end
end
