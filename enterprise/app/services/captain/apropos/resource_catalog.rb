class Captain::Apropos::ResourceCatalog
  ENTITIES = {
    'accounts' => { fields: %w[id name], query: %w[name], relations: {} },
    'contacts' => { fields: %w[id name email phone_number identifier custom_attributes additional_attributes created_at last_activity_at],
                    query: %w[name email phone_number],
                    description: 'Use related contact-ref "conversations" for all statuses, or "notes" for internal profile notes. ' \
                                 'Both return {items, next_cursor}, ascending database ID, 50 per page; follow cursors to completion.',
                    relations: { 'conversations' => ['conversations', 'contact_id', :many], 'notes' => ['contact_notes', 'contact_id', :many] } },
    'contact_notes' => { fields: %w[id content contact_id user_id created_at updated_at], query: %w[content],
                         description: 'Internal profile notes, not conversation messages. user_id identifies the last editing user.',
                         relations: { 'contact' => ['contacts', 'contact_id', :one], 'user' => ['agents', 'user_id', :one] } },
    'assistants' => { fields: %w[id name description], query: %w[name description], relations: { 'faqs' => ['faqs', 'assistant_id', :many] } },
    'conversations' => { fields: %w[id display_id status priority contact_id inbox_id assignee_id team_id
                                    custom_attributes created_at last_activity_at snoozed_until],
                         query_fields: { 'labels' => :string_list },
                         query: [], relations: { 'messages' => ['messages', 'conversation_id', :many],
                                                 'contact' => ['contacts', 'contact_id', :one], 'inbox' => ['inboxes', 'inbox_id', :one],
                                                 'team' => ['teams', 'team_id', :one], 'assignee' => ['agents', 'assignee_id', :one] } },
    'messages' => { fields: %w[id content message_type private conversation_id created_at], query: %w[content],
                    relations: { 'conversation' => ['conversations', 'conversation_id', :one] } },
    'inboxes' => { fields: %w[id name channel_type], query: %w[name],
                   relations: { 'conversations' => ['conversations', 'inbox_id', :many],
                                'assignable_agents' => ['agents', 'assignable_agents', :scoped] },
                   description: 'Use (related inbox-ref "assignable_agents") to read eligible agents before assignment. ' \
                                'Use assignment-context for live capacity and assignment policy checks. ' \
                                'The scoped relationship uses the same eligibility rules as assign-agent and is not a WootQL join.' },
    'teams' => { fields: %w[id name description], query: %w[name description],
                 relations: { 'conversations' => ['conversations', 'team_id', :many] } },
    'labels' => { fields: %w[id title description color show_on_sidebar created_at updated_at], query: %w[title description], relations: {} },
    'agents' => { fields: %w[id name email], query: %w[name email],
                  relations: { 'conversations' => ['conversations', 'assignee_id', :many] } },
    'articles' => { fields: %w[id title content description status portal_id], query: %w[title content], relations: {} },
    'faqs' => { fields: %w[id question answer assistant_id], query: %w[question answer], relations: {} }
  }.freeze
end
