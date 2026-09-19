class Captain::Llm::WidgetTaglineSchema < RubyLLM::Schema
  string :tagline,
         description: 'Short marketing tagline for a customer-support chat widget. Plain text, no quotes, no emoji, no trailing punctuation.',
         max_length: 60
end
