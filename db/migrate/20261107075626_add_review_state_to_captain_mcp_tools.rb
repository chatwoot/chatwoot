class AddReviewStateToCaptainMcpTools < ActiveRecord::Migration[7.2]
  def change
    add_column :captain_mcp_tools, :review_state, :string, null: false, default: 'current'
    remove_column :captain_mcp_servers, :tools_changed_at, :datetime
  end
end
