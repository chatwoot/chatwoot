class CreateCaptainAproposSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :captain_apropos_sessions do |t|
      t.bigint :account_id, null: false
      t.bigint :user_id, null: false
      t.string :status, null: false, default: 'ready'
      t.jsonb :messages, null: false, default: []
      t.jsonb :state, null: false, default: {}
      t.jsonb :trace, null: false, default: []

      t.timestamps
    end
    add_index :captain_apropos_sessions, [:account_id, :user_id]
  end
end
