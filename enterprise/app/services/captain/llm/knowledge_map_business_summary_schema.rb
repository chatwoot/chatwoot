class Captain::Llm::KnowledgeMapBusinessSummarySchema < RubyLLM::Schema
  string :business_summary,
         description: 'A compact description of the business or product represented by the supplied topics.',
         max_length: 1500
  array :business_summary_faq_ids,
        description: 'Approved FAQ IDs that support the business summary.',
        min_items: 1,
        max_items: 100,
        of: :integer
end
