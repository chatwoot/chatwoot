class Captain::Llm::KnowledgeMapSchema < RubyLLM::Schema
  integer :version, description: 'Knowledge map schema version. Always 1.'
  string :business_summary,
         description: 'A compact, evidence-backed description of the business or product represented by the knowledge.',
         max_length: 1000
  array :business_summary_faq_ids,
        description: 'Approved FAQ IDs that support the business summary.',
        min_items: 1,
        max_items: 12,
        of: :integer

  array :topics, description: 'The main product or business domains represented in the knowledge.', min_items: 1, max_items: 12 do
    object do
      string :name, description: 'A short, reusable topic name.', max_length: 80
      string :summary, description: 'What this topic covers and why it matters.', max_length: 400
      array :faq_ids, description: 'Approved FAQ IDs supporting this topic.', min_items: 1, max_items: 12, of: :integer
      array :concepts, description: 'Important terminology, entities, features, or workflows in this topic.',
                       min_items: 1, max_items: 10, of: :string

      array :relationships, description: 'Important evidence-backed connections between concepts.', max_items: 6 do
        object do
          string :subject, description: 'The source concept in the relationship.', max_length: 100
          string :predicate, description: 'A concise relationship such as configures, requires, or differs from.', max_length: 80
          string :object, description: 'The target concept in the relationship.', max_length: 100
          array :faq_ids, description: 'Approved FAQ IDs supporting this relationship.',
                          min_items: 1, max_items: 12, of: :integer
        end
      end

      array :distinctions, description: 'Easy-to-confuse alternatives, scopes, conditions, or trade-offs.', max_items: 6 do
        object do
          string :statement, description: 'A concise explanation of the distinction.', max_length: 300
          array :faq_ids, description: 'Approved FAQ IDs supporting this distinction.',
                          min_items: 1, max_items: 12, of: :integer
        end
      end
    end
  end
end
