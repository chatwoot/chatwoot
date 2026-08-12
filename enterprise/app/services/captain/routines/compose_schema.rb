class Captain::Routines::ComposeSchema < RubyLLM::Schema
  array :segments, description: 'Ordered typed segments that form the complete message.', min_items: 1 do
    object do
      string :type, enum: %w[text mention], description: 'Whether this segment is literal text or a declared account-user mention.'
      optional :text, description: 'Literal message text when type is text; null when type is mention.' do
        string
      end
      optional :mention, description: 'Declared mention binding name when type is mention; null when type is text.' do
        string
      end
    end
  end
end
