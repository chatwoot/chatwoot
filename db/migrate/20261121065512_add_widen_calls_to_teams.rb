class AddWidenCallsToTeams < ActiveRecord::Migration[8.0]
  def change
    add_column :teams, :widen_calls, :integer, null: false, default: 0
  end
end
