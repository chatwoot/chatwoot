class AddCustomAttributeDefinition < ActiveRecord::Migration[6.0]
  def change
    create_table :custom_attribute_definitions do |t|
      t.string :attribute_display_name
      t.string :attribute_key
      t.integer :attribute_display_type, default: 0
      t.integer :default_value
      t.integer :attribute_model, default: 0
      t.references :account, index: true

      t.timestamps
    end

    add_index :custom_attribute_definitions, [:attribute_key, :attribute_model], unique: true, name: 'attribute_key_model_index'
  end
end
