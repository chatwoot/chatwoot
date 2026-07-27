class Captain::Llm::KnowledgeMapTopicDiscoverySchema < RubyLLM::Schema
  array :topics, description: 'Distinct product or business topics found in this FAQ batch.', max_items: 100 do
    object do
      string :name, description: 'A short, reusable topic name.', max_length: 100
      string :summary, description: 'What the topic covers.', max_length: 300
      array :concepts, description: 'Important terminology, entities, features, or workflows.',
                       max_items: 12, of: :string
      array :faq_ids, description: 'Every input FAQ ID assigned to this topic.',
                      min_items: 1, max_items: 1000, of: :integer
    end
  end

  array :ignored_faq_ids,
        description: 'Input FAQ IDs that contain no reusable product or business context.',
        max_items: 1000,
        of: :integer
end
