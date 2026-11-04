class AddHeadersToCaptainCustomTools < ActiveRecord::Migration[7.2]
  def change
    add_column :captain_custom_tools, :headers, :jsonb, default: {}, null: false
  end
end
