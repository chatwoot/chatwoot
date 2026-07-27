class Captain::Llm::KnowledgeMapTopicCanonicalizationSchema < RubyLLM::Schema
  array :topics, description: 'Canonical topics covering every supplied candidate exactly once.',
                 min_items: 1, max_items: 100 do
    object do
      string :name, description: 'A short canonical topic name.', max_length: 100
      string :summary, description: 'The combined scope of the candidate topics.', max_length: 300
      array :concepts, description: 'Representative concepts from the grouped candidates.',
                       max_items: 12, of: :string
      array :candidate_ids, description: 'Candidate IDs grouped into this canonical topic.',
                            min_items: 1, max_items: 1000, of: :string
    end
  end
end
