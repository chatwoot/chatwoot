class AddCustomAttributesToLibraryResources < ActiveRecord::Migration[7.1]
  def change
    add_column :library_resources, :custom_attributes, :jsonb, default: {}
    add_index :library_resources, :custom_attributes, using: :gin
  end
end
