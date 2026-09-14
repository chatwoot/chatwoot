class Captain::Apropos::ResourceCatalog
  ENTITIES = {
    'accounts' => { query: %w[name], relations: {} },
    'contacts' => { query: %w[name email phone_number],
                    description: 'Use related contact-ref "conversations" for all statuses, or "notes" for internal profile notes. ' \
                                 'Both return {items, next_cursor}, ascending database ID, 50 per page; follow cursors to completion.',
                    relations: { 'conversations' => ['conversations', 'contact_id', :many], 'notes' => ['contact_notes', 'contact_id', :many] } },
    'contact_notes' => { query: %w[content],
                         description: 'Internal profile notes, not conversation messages. user_id identifies the last editing user.',
                         relations: { 'contact' => ['contacts', 'contact_id', :one], 'user' => ['agents', 'user_id', :one] } },
    'assistants' => { query: %w[name description], relations: { 'faqs' => ['faqs', 'assistant_id', :many] } },
    'conversations' => { query_fields: { 'labels' => :string_list },
                         query: [], relations: { 'messages' => ['messages', 'conversation_id', :many],
                                                 'contact' => ['contacts', 'contact_id', :one], 'inbox' => ['inboxes', 'inbox_id', :one],
                                                 'team' => ['teams', 'team_id', :one], 'assignee' => ['agents', 'assignee_id', :one] } },
    'messages' => { description: 'sender_type and sender_id jointly identify the author: Captain::Assistant, User, Contact, or AgentBot. ' \
                                 'Message type, visibility, and delivery status are independent properties.',
                    query: %w[content],
                    relations: { 'conversation' => ['conversations', 'conversation_id', :one] } },
    'inboxes' => { query: %w[name],
                   relations: { 'conversations' => ['conversations', 'inbox_id', :many],
                                'assignable_agents' => ['agents', 'assignable_agents', :scoped] },
                   description: 'Use (related inbox-ref "assignable_agents") to read eligible agents before assignment. ' \
                                'Use assignment-context for live capacity and assignment policy checks. ' \
                                'The scoped relationship uses the same eligibility rules as assign-agent and is not a WootQL join.' },
    'teams' => { query: %w[name description],
                 relations: { 'conversations' => ['conversations', 'team_id', :many] } },
    'labels' => { query: %w[title description], relations: {} },
    'agents' => { query: %w[name email],
                  relations: { 'conversations' => ['conversations', 'assignee_id', :many] } },
    'articles' => { query: %w[title content], relations: {} },
    'faqs' => { query: %w[question answer], relations: {} }
  }.freeze

  def self.entries
    ENTITIES.keys.index_with { |resource| fetch(resource) }
  end

  def self.fetch(resource)
    definition = ENTITIES.fetch(resource)
    relations = Captain::Apropos::ResourceRelationships.for(resource).merge(definition.fetch(:relations))
    definition.merge(fields: Captain::Apropos::ResourceFields.for(resource), relations: relations)
  end
end
