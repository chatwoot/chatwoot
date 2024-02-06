class CreateAppliedSlas < ActiveRecord::Migration[7.0]
  def change
    create_table :applied_slas do |t|
      t.references :account, null: false
      t.references :sla_policy, null: false
      t.references :conversation, null: false

      t.string :sla_status

      t.timestamps
    end
  end
end
