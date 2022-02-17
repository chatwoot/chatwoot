class AddValuesToCustomAttributeDefinitions < ActiveRecord::Migration[6.1]
  def change
    add_column :custom_attribute_definitions, :values, :jsonb, default: []
  end
end
