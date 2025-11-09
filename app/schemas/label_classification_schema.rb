# frozen_string_literal: true

class LabelClassificationSchema < RubyLLM::Schema
  integer :label_id, description: 'The ID of the most relevant label from the available labels list'
end
