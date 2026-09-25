class EnqueueBackfillContactTypeJob < ActiveRecord::Migration[7.1]
  def up
    Migration::BackfillContactTypeJob.perform_later
  end

  def down; end
end
