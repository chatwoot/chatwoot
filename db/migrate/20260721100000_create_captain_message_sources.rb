class CreateCaptainMessageSources < ActiveRecord::Migration[7.1]
  def change
    create_table :captain_message_sources do |t|
      t.references :account, null: false, index: true
      t.references :assistant, null: false, index: true
      t.references :conversation, null: false, index: true
      t.references :message, null: false, index: true
      t.references :document, null: false, index: true
      t.bigint :assistant_response_id, null: false

      t.timestamps
    end

    add_index :captain_message_sources, [:message_id, :assistant_response_id],
              unique: true, name: 'idx_captain_message_sources_on_message_and_response'
  end
end
