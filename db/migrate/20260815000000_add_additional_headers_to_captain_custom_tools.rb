class AddAdditionalHeadersToCaptainCustomTools < ActiveRecord::Migration[7.1]
  def change
    add_column :captain_custom_tools, :additional_headers, :jsonb, default: {}, null: false
  end
end
