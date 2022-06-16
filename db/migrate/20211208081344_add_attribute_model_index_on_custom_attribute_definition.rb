class AddAttributeModelIndexOnCustomAttributeDefinition < ActiveRecord::Migration[6.1]
  def change
    remove_index :custom_attribute_definitions, [:attribute_key, :account_id], name: 'attribute_key_index',
                                                                               if_exists: true
    add_index :custom_attribute_definitions, [:attribute_key, :attribute_model, :account_id], unique: true, name: 'attribute_key_model_index',
                                                                                              if_not_exists: true
  end
end
