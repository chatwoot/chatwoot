class CreateCustomApis < ActiveRecord::Migration[7.0]
  def change
    create_table :custom_apis do |t|
      t.string :name, null: false
      t.string :base_url, null: false
      t.string :api_key, null: false

      t.timestamps
    end
  end
end
