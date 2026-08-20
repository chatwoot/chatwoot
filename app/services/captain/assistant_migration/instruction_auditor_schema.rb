class Captain::AssistantMigration::InstructionAuditorSchema < RubyLLM::Schema
  STRING_ARRAYS = {
    response_guidelines: ['Missing active behavior to append to the generated response guidelines.', 10],
    guardrails: ['Missing active boundaries or prohibitions to append to the generated guardrails.', 10],
    needs_review: ['Missing source behavior blocked by an unavailable tool or runtime capability.', 10]
  }.freeze

  def self.for(available_additions)
    Class.new(RubyLLM::Schema).tap do |schema|
      add_string_arrays(schema, available_additions)
      add_scenarios(schema, available_additions[:scenario_candidates])
      add_faqs(schema, available_additions[:faq_document_candidates])
    end
  end

  def self.add_string_arrays(schema, available_additions)
    STRING_ARRAYS.each do |name, (description, limit)|
      next unless available_additions[name].positive?

      schema.array(name, description: description, max_items: [available_additions[name], limit].min, of: :string)
    end
  end

  def self.add_scenarios(schema, available)
    return unless available.positive?

    schema.array :scenario_candidates,
                 description: 'Missing distinct multi-step workflows to append to the generated scenario candidates.',
                 max_items: [available, 5].min do
      object do
        string :title, max_length: 80
        string :description, max_length: 500
        string :instruction, max_length: 2000
        string :response_guideline, max_length: 1000
        array :tool_ids, max_items: 10, of: :string
      end
    end
  end

  def self.add_faqs(schema, available)
    return unless available.positive?

    schema.array :faq_document_candidates,
                 description: 'Missing factual product or business knowledge to append to the pending FAQ candidates.',
                 max_items: [available, 15].min do
      object do
        string :question, max_length: 255
        string :answer, max_length: 2000
      end
    end
  end
end
