class CreateInstallationConfig < ActiveRecord::Migration[6.0]
  def change
    create_table :installation_configs do |t|
      t.string :name, null: false
      t.jsonb :serialized_value, null: false, default: '{}'
      t.timestamps
    end

    add_index :installation_configs, [:name, :created_at], unique: true

    ConfigLoader.new.process
  end
end
