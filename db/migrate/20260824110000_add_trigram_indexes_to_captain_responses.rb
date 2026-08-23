class AddTrigramIndexesToCaptainResponses < ActiveRecord::Migration[7.2]
  # Backs the hybrid keyword-retrieval layer (exact SKU / promo-code / part-number
  # matching) on captain_assistant_responses. pg_trgm is already enabled by the
  # init schema; these GIN trigram indexes make the word_similarity lookups fast
  # and are tiny compared with the dropped embedding ANN index.
  def up
    add_index :captain_assistant_responses, :question,
              using: :gin, opclass: :gin_trgm_ops,
              name: 'index_captain_assistant_responses_on_question_trgm'
    add_index :captain_assistant_responses, :answer,
              using: :gin, opclass: :gin_trgm_ops,
              name: 'index_captain_assistant_responses_on_answer_trgm'
  end

  def down
    remove_index :captain_assistant_responses, name: 'index_captain_assistant_responses_on_question_trgm'
    remove_index :captain_assistant_responses, name: 'index_captain_assistant_responses_on_answer_trgm'
  end
end
