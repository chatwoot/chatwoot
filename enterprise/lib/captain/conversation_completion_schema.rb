class Captain::ConversationCompletionSchema < Schematist::Schema
  string :outcome, enum: %w[complete waiting_on_customer needs_human], description: 'What should happen to the inactive conversation next'
  string :reason, description: 'Brief explanation of the chosen outcome'
end
