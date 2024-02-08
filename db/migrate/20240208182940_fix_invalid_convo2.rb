class FixInvalidConvo2 < ActiveRecord::Migration[7.0]
  def change
    Migration::FixInvalidEmailsJob.perform_later
  end
end
