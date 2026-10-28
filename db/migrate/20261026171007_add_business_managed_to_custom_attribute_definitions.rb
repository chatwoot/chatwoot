class AddBusinessManagedToCustomAttributeDefinitions < ActiveRecord::Migration[7.2]
  def change
    add_column :custom_attribute_definitions, :business_managed, :boolean, default: false, null: false
  end
end
