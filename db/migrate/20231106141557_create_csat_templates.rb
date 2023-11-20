class CreateCsatTemplates < ActiveRecord::Migration[7.0]
  def change
    create_table :csat_templates do |t|
      t.references :account, null: false
      t.timestamps
    end
  end
end
