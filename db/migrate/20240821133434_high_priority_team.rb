class HighPriorityTeam < ActiveRecord::Migration[7.0]
  def change
    add_column :teams, :high_priority, :boolean, default: false
  end
end
