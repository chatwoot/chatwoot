class AddCreateByAgentLabel < ActiveRecord::Migration[7.0]
  def change
    Migration::AddNewLabelsJob.perform_later
  end
end
