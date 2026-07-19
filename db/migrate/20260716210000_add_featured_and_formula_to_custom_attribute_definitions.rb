class AddFeaturedAndFormulaToCustomAttributeDefinitions < ActiveRecord::Migration[7.1]
  def change
    add_column :custom_attribute_definitions, :featured, :boolean, default: false, null: false
    add_column :custom_attribute_definitions, :formula, :jsonb
  end
end
