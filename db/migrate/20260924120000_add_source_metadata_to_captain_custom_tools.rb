class AddSourceMetadataToCaptainCustomTools < ActiveRecord::Migration[7.2]
  def change
    add_column :captain_custom_tools, :source_metadata, :jsonb
  end
end
