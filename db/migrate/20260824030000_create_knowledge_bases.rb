class CreateKnowledgeBases < ActiveRecord::Migration[7.1]
  def change
    create_table :knowledge_bases do |t|
      t.bigint :account_id, null: false
      t.string :name, null: false
      t.text :content, null: false
      t.string :category
      t.vector :embedding, limit: 1536
      t.boolean :enabled, null: false, default: true
      t.timestamps
    end

    add_index :knowledge_bases, :account_id
    add_index :knowledge_bases, [:account_id, :category]
    add_index :knowledge_bases, :embedding, using: :ivfflat, opclass: :vector_cosine_ops
  end
end
