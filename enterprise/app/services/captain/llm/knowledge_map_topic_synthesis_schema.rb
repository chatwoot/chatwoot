class Captain::Llm::KnowledgeMapTopicSynthesisSchema < RubyLLM::Schema
  array :topics, description: 'One synthesized topic for every supplied topic task.',
                 min_items: 1, max_items: 5 do
    object do
      string :topic_key, description: 'The exact topic key supplied with the task.', max_length: 100
      string :summary, description: 'What this topic covers and why it matters.', max_length: 400
      array :faq_ids, description: 'Representative approved FAQ IDs supporting the topic.',
                      min_items: 1, max_items: 1000, of: :integer
      array :covered_faq_ids, description: 'Every FAQ ID processed for this topic task.',
                              min_items: 1, max_items: 1000, of: :integer
      array :concepts, description: 'Important terminology, entities, features, or workflows.',
                       max_items: 12, of: :string

      array :relationships, description: 'Important evidence-backed connections between concepts.', max_items: 6 do
        object do
          string :subject, description: 'The source concept in the relationship.', max_length: 100
          string :predicate, description: 'A concise relationship such as configures, requires, or differs from.',
                             max_length: 80
          string :object, description: 'The target concept in the relationship.', max_length: 100
          array :faq_ids, description: 'Approved FAQ IDs supporting this relationship.',
                          min_items: 1, max_items: 1000, of: :integer
        end
      end

      array :distinctions, description: 'Easy-to-confuse alternatives, scopes, conditions, or trade-offs.', max_items: 6 do
        object do
          string :statement, description: 'A concise explanation of the distinction.', max_length: 300
          array :faq_ids, description: 'Approved FAQ IDs supporting this distinction.',
                          min_items: 1, max_items: 1000, of: :integer
        end
      end
    end
  end
end
