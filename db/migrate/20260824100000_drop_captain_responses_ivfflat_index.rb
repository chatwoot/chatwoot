class DropCaptainResponsesIvfflatIndex < ActiveRecord::Migration[7.2]
  # The captain_assistant_responses.embedding column used an IVFFlat index built
  # with vector_l2_ops while queries compare with cosine distance, causing an
  # operator mismatch and missed matches that required a `SET LOCAL
  # enable_indexscan = off` workaround. For corpora below ~5k rows a brute-force
  # cosine scan has perfect recall and outperforms ANN, so the index is dropped
  # and the btree indexes on assistant_id/account_id/status (used by the scoped
  # lookup) are kept.
  def up
    remove_index :captain_assistant_responses, name: 'vector_idx_knowledge_entries_embedding'
  end

  def down
    add_index :captain_assistant_responses, :embedding,
              using: :ivfflat,
              name: 'vector_idx_knowledge_entries_embedding',
              opclass: :vector_l2_ops
  end
end
