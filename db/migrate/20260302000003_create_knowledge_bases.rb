# frozen_string_literal: true

class CreateKnowledgeBases < ActiveRecord::Migration[7.1]
  def change
    create_table :knowledge_bases do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :ai_agent, null: false, foreign_key: true, index: true

      t.string :name, null: false
      t.text :description
      t.integer :status, null: false, default: 0 # enum: active, processing, error

      t.timestamps
    end
  end
end
