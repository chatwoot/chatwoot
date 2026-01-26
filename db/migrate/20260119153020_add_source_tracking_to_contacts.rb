class AddSourceTrackingToContacts < ActiveRecord::Migration[7.0]
  def change
    add_column :contacts, :source_type, :integer, default: 0, null: false
    add_column :contacts, :source_metadata, :jsonb, default: {}

    add_index :contacts, :source_type
    add_index :contacts, :source_metadata, using: :gin
  end
end
