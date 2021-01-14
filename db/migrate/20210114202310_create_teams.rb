class CreateTeams < ActiveRecord::Migration[6.0]
  def change
    create_table :teams do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :allow_auto_assign, default: true
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
