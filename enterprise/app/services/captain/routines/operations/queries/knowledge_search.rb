class Captain::Routines::Operations::Queries::KnowledgeSearch < Captain::Routines::Operations::Query
  returns :collection

  configure(
    name: 'knowledge.search', effect: 'read', approval: 'never',
    description: 'Search accessible FAQs, help-center articles, and Captain documents.',
    arguments: {
      query: 'semantic search query', language: 'optional language code', limit: 'maximum number of results'
    },
    required: %w[query]
  )
end
