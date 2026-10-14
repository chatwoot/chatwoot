class CreateCaptainFaqSuggestions < ActiveRecord::Migration[7.1]
  def change
    create_faq_suggestions
    create_faq_observations
  end

  private

  def create_faq_suggestions
    create_table :captain_faq_suggestions do |t|
      t.string :question, null: false
      t.text :answer, null: false
      t.vector :embedding, limit: 1536
      t.references :assistant, null: false, index: true
      t.references :account, null: false, index: true
      t.string :language, null: false, default: 'en'
      t.integer :source_count, null: false, default: 0
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :captain_faq_suggestions, [:account_id, :assistant_id, :status, :language],
              name: 'idx_cap_faq_suggestions_on_account_assistant_status_language'
    add_index :captain_faq_suggestions, :embedding, using: :ivfflat,
                                                    name: 'vector_idx_captain_faq_suggestions_embedding',
                                                    opclass: :vector_cosine_ops
  end

  def create_faq_observations
    create_table :captain_faq_observations do |t|
      t.references :account, null: false, index: true
      t.references :conversation, null: false, index: true
      t.references :faq_suggestion, index: true
      t.string :generated_question, null: false
      t.text :generated_answer, null: false
      t.string :language, null: false, default: 'en'
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :captain_faq_observations, [:conversation_id, :faq_suggestion_id],
              unique: true,
              where: 'faq_suggestion_id IS NOT NULL',
              name: 'idx_captain_faq_observations_on_conversation_and_suggestion'
  end
end
