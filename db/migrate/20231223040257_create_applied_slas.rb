class CreateAppliedSlas < ActiveRecord::Migration[7.0]
  def change
    create_table :applied_slas do |t|
      t.references :account, null: false, foreign_key: true
      t.references :sla_policy, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true

      t.string :sla_id
      t.string :sla_status

      t.timestamps
    end
  end
end
