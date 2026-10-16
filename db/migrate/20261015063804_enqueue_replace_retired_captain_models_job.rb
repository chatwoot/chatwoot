class EnqueueReplaceRetiredCaptainModelsJob < ActiveRecord::Migration[7.2]
  def up
    Migration::ReplaceRetiredCaptainModelsJob.perform_later
  end

  def down; end
end
