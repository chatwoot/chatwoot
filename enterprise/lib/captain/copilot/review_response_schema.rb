class Captain::Copilot::ReviewResponseSchema < Schematist::Schema
  boolean :matched
  boolean :needs_more_history
  string :category
  string :reason
  array :evidence_message_ids, of: :integer
end
