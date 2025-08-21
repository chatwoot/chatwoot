class AddResourceTypeToLibraryResources < ActiveRecord::Migration[7.1]
  def change
    add_column :library_resources, :resource_type, :string, null: false, default: 'text'
    add_index :library_resources, :resource_type
  end
end
