class CreateSavedReportPanels < ActiveRecord::Migration[7.1]
  def change
    create_table :saved_report_panels do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }, index: true
      t.string :name, null: false
      t.text :description
      t.string :date_preset, null: false, default: 'last_7_days'
      t.bigint :custom_since
      t.bigint :custom_until
      t.boolean :business_hours, null: false, default: false
      t.boolean :favorite, null: false, default: false
      t.jsonb :filters, null: false, default: []
      t.jsonb :widgets, null: false, default: []
      t.timestamps
    end

    add_index :saved_report_panels, [:account_id, :favorite]
  end
end
