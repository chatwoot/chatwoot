class RerunTicketLabelsJob < ActiveRecord::Migration[7.0]
  def change
    Migration::SetupTicketLabelsJob.perform_later
  end
end
