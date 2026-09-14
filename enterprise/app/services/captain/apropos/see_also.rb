module Captain::Apropos::SeeAlso
  # Links describe neighboring capabilities, not preferred plans. Keep them curated
  # and shallow so discovery opens useful paths without recursively loading contracts.
  LINKS = {
    'search' => {
      'query-data' => 'Joins, aggregates, rankings, or retrieval described in natural language.',
      'related' => 'Follow a declared relationship from a record already identified.'
    },
    'fetch' => {
      'related' => 'Explore records connected to this record.',
      'search' => 'Find records when their references are not yet known.'
    },
    'related' => {
      'query-data' => 'Retrieve or aggregate across multiple records instead of traversing each separately.',
      'resources' => 'Inspect available resources and their relationships.'
    },
    'query-data' => {
      'query-run' => 'Execute a known WootQL query with parameters, without another model call.',
      'query-map' => 'Process every result page with a Scheme function.'
    },
    'query-run' => {
      'query-data' => 'A query specialist can translate a retrieval request into WootQL.',
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
      'delegate' => 'A fresh worker can investigate with tools rather than only evaluate supplied data.',
      'collections' => 'Counts, grouping, and other deterministic transformations need no model call.'
    },
    'delegate' => {
      'reason' => 'Evaluate supplied evidence without tool access.',
      'map-agent' => 'Run independent workers over a collection of inputs.'
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
