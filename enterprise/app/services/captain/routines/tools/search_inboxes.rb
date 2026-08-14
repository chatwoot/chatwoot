class Captain::Routines::Tools::SearchInboxes < Captain::Routines::Tools::Base
  description 'Search live inboxes in the Routine account by partial name and pin a unique match as a resource'
  param :reference, type: 'string', desc: 'Stable snake_case resource name, for example support_inbox'
  param :query, type: 'string', desc: 'Inbox name from the administrator instruction'

  def name = 'search_inboxes'

  def perform(tool_context, reference:, query:)
    candidates = account(tool_context).inboxes
                                      .where('inboxes.name ILIKE ?', search_term(query))
                                      .order(:name, :id)
                                      .limit(10)
                                      .map do |inbox|
      {
        'type' => 'inbox', 'id' => inbox.id, 'name' => inbox.name,
        'channel_type' => inbox.channel_type, 'timezone' => inbox.timezone
      }
    end
    exact_candidates = candidates.select { |candidate| exact?(query, candidate['name']) }
    search_response(tool_context, reference: reference, query: query, candidates: candidates, exact_candidates: exact_candidates)
  end
end
