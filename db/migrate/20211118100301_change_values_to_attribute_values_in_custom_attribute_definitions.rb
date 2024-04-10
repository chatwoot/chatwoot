class ChangeValuesToAttributeValuesInCustomAttributeDefinitions < ActiveRecord::Migration[6.1]
  def change
    rename_column :custom_attribute_definitions, :values, :attribute_values
  end
end
