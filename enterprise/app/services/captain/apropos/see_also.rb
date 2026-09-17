module Captain::Apropos::SeeAlso
  # Links describe neighboring capabilities, not preferred plans. Keep them curated
  # and shallow so discovery opens useful paths without recursively loading contracts.
  LINKS = {
    'search' => {
      'query-run' => 'Use WootQL for joins, aggregates, rankings, or bulk retrieval.',
      'related' => 'Follow a declared relationship from a record already identified.'
    },
    'fetch' => {
      'related' => 'Explore records connected to this record.',
      'search' => 'Find records when their references are not yet known.'
    },
    'related' => {
      'query-run' => 'Retrieve or aggregate across multiple records instead of traversing each separately.',
      'resources' => 'Inspect available resources and their relationships.'
    },
    'query-run' => {
      'wootql' => 'Inspect the query language and its stage contracts.',
      'resources' => 'Inspect fields and relationships before writing a query.',
      'query-map' => 'Process every result page with a Scheme function.',
      'collections' => 'Transform retrieved rows locally, including sequence processing beyond WootQL.'
    },
    'agents' => {
      'assignment-context' => 'Live inbox eligibility, presence, policy capacity, and rate limits, distinct from assigned workload.',
      'related' => 'Follow an agent reference to currently assigned conversations.'
    },
    'inboxes' => {
      'assignment-context' => 'Inspect assignment policy and agent capacity for an inbox.',
      'related' => 'Explore inbox conversations or its assignable agents.'
    },
    'assignment-context' => {
      'conversations' => 'Investigate the work behind assignment counts.',
      'assign-agent' => 'Perform an assignment; reading capacity does not reserve or assign anything.'
    },
    'assign-agent' => {
      'assignment-context' => 'Inspect inbox eligibility, live presence, and capacity as separate dimensions.',
      'receipts' => 'Inspect recorded action outcomes, including earlier attempts.'
    },
    'articles' => {
      'faq-search' => 'Semantic search of approved Captain FAQ answers, a separate knowledge source.'
    },
    'faqs' => {
      'faq-search' => 'Find approved FAQ answers by semantic relevance rather than text matching.'
    },
    'reason' => {
      'spawn-agent' => 'A fresh autonomous worker can retrieve evidence and use tools rather than only evaluate supplied data.',
      'collections' => 'Counts, grouping, and other deterministic transformations need no model call.'
    },
    'spawn-agent' => {
      'reason' => 'Evaluate supplied evidence without tool access.',
      'map' => 'Run a fresh worker for every independent item in a collection.'
    },
    'show-table' => {
      'collections' => 'Project, group, and order data before presenting it.'
    }
  }.freeze

  def self.attach(entries)
    entries.to_h do |name, details|
      links = LINKS[name]
      [name, links ? details.merge(see_also: links) : details]
    end
  end
end
