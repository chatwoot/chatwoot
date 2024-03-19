class CreateSlaEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :sla_events do |t|
      t.references :applied_sla, null: false
      t.references :conversation, null: false

      t.string :event_type
      t.jsonb :metadata

      t.timestamps
    end
  end
end
