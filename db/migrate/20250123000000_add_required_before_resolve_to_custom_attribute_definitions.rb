class AddRequiredBeforeResolveToCustomAttributeDefinitions < ActiveRecord::Migration[7.0]
  def change
    add_column :custom_attribute_definitions, :required_before_resolve, :boolean, default: false, null: false
  end
end
