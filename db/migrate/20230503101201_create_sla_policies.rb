class CreateSlaPolicies < ActiveRecord::Migration[6.1]
  def change
    create_table :sla_policies do |t|
      t.string :name, null: false
      t.float :frt_threshold, default: nil
      t.float :rt_threshold, default: nil
      t.boolean 'only_during_business_hours', default: false
      t.references :account, index: true, null: false

      t.timestamps
    end
  end
end
