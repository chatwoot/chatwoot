class Captain::Copilot::ReviewResponseSchema < Schematist::Schema
  array :results do
    object do
      integer :conversation_id
      boolean :needs_attention
      boolean :needs_more_history
      string :category
      string :reason
      array :evidence_message_ids, of: :integer
    end
  end
end
