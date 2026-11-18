class Captain::ConversationCompletionSchema < Schematist::Schema
  OUTCOMES = %w[complete waiting_on_customer needs_human].freeze

  string :outcome, enum: OUTCOMES, description: 'What should happen to the inactive conversation next'
  string :reason, description: 'Brief explanation of the chosen outcome'
end
