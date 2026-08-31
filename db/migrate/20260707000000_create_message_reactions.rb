class CreateMessageReactions < ActiveRecord::Migration[7.0]
  def change
    create_table :message_reactions do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :inbox, null: false, foreign_key: true, index: true
      t.references :conversation, null: false, foreign_key: true, index: true
      t.references :message, null: false, foreign_key: true, index: true
      t.references :sender, polymorphic: true, index: true
      t.string :actor_external_id
      t.string :source_id
      t.string :external_message_id, null: false
      t.string :emoji
      t.string :reaction_type
      t.integer :direction, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.datetime :external_created_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_message_reaction_indexes
  end

  private

  def add_message_reaction_indexes
    add_index :message_reactions, :source_id, unique: true, where: 'source_id IS NOT NULL'
    add_index :message_reactions,
              [:message_id, :direction, :external_message_id, :actor_external_id],
              unique: true,
              where: 'actor_external_id IS NOT NULL',
              name: 'idx_message_reactions_on_logical_identity'
  end
end
