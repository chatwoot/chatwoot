class CreateSynapseosMonthlyReports < ActiveRecord::Migration[7.1]
  def change
    create_table :synapseos_monthly_reports do |t|
      t.references :account, null: false, foreign_key: { to_table: :accounts }
      t.string :period, null: false            # 'YYYY-MM' (mês de referência)
      t.string :title
      t.datetime :generated_at, null: false
      t.jsonb :data, null: false, default: {}   # payload do relatório (números por seção)

      t.timestamps
    end

    add_index :synapseos_monthly_reports, [:account_id, :period], unique: true
  end
end
