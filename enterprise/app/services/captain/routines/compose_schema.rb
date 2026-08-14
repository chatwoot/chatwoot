class Captain::Routines::ComposeSchema < RubyLLM::Schema
  array :segments, description: 'Ordered typed segments that form the complete message.', min_items: 1 do
    object do
      string :type, enum: %w[text mention], description: 'Whether this segment is literal text or a declared account-user mention.'
      string :value, min_length: 1, description: 'Literal text or the declared mention binding name, according to the segment type.'
    end
  end
end
