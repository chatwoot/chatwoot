class Captain::Routines::ComposeSchema < RubyLLM::Schema
  array :segments, description: 'Ordered typed segments that form the complete message.', min_items: 1 do
    object do
      string :type, enum: %w[text mention], description: 'Whether this segment is literal text or a declared account-user mention.'
      string :text, required: false, description: 'Literal message text. Required only when type is text.'
      string :mention, required: false, description: 'Declared mention binding name. Required only when type is mention.'
    end
  end
end
