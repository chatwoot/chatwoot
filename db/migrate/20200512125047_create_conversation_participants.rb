class CreateConversationParticipants < ActiveRecord::Migration[6.0]
  def change
    enable_extension 'pgcrypto'
    create_table :conversation_participants do |t|
      t.references :contact, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.uuid :uuid, default: 'gen_random_uuid()', null: false
      # contact who started conversation(is primay)
      # contact who joined group conversation(is not primary)
      t.boolean :primary, default: true, null: false
      t.timestamps
    end

    add_index :conversation_participants,
              [:contact_id, :conversation_id],
              unique: true,
              name: 'index_conversation_participants_contact_conversation'
  end
end
