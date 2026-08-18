class AddDisplayNameToCalendarConnections < ActiveRecord::Migration[7.1]
  def change
    add_column :calendar_connections, :display_name, :string
  end
end
