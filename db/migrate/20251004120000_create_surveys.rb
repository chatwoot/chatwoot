class CreateSurveys < ActiveRecord::Migration[7.1]
  def change
    create_table :surveys do |t|
      t.string :name, null: false
      t.text :description
      t.references :account, null: false, foreign_key: true, index: true
      t.boolean :active, default: true, null: false

      t.timestamps
    end
  end
end
