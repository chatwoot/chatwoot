class CreateSmartVariables < ActiveRecord::Migration[7.0]
  def change
    create_table :smart_variables do |t|
      t.timestamps

      t.string :name, null: false
      t.jsonb :data, default: {}
    end
  end
end
