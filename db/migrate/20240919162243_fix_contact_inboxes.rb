class FixContactInboxes < ActiveRecord::Migration[7.0]
  def change
    Migration::FixContactInboxesJob.perform_later
  end
end
