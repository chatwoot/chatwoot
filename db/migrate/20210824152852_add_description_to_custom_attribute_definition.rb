class AddDescriptionToCustomAttributeDefinition < ActiveRecord::Migration[6.1]
  def change
    add_column :custom_attribute_definitions, :attribute_description, :text
  end
end
