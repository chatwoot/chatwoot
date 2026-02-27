class CreateInsights < ActiveRecord::Migration[7.0]
  def change
    create_table :insights do |t|
      t.string :name, null: false
      t.jsonb :config, default: {}
      t.references :account, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
