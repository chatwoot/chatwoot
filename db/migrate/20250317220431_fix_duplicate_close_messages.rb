class FixDuplicateCloseMessages < ActiveRecord::Migration[7.0]
  def change
    Migration::FixClosedActivityJob.perform_later
  end
end
