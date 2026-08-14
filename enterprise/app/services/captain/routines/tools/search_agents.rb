class Captain::Routines::Tools::SearchAgents < Captain::Routines::Tools::Base
  description 'Search live agents in the Routine account by partial name or email and pin a unique match as a resource'
  param :reference, type: 'string', desc: 'Stable snake_case resource name, for example jithin'
  param :query, type: 'string', desc: 'Agent name or email from the administrator instruction'

  def name = 'search_agents'

  def perform(tool_context, reference:, query:)
    current_account = account(tool_context)
    candidates = current_account.users
                                .where('users.name ILIKE :term OR users.email ILIKE :term', term: search_term(query))
                                .order(:name, :id)
                                .limit(10)
                                .map do |agent|
      account_user = current_account.account_users.find_by(user_id: agent.id)
      {
        'type' => 'agent', 'id' => agent.id, 'name' => agent.name, 'email' => agent.email,
        'availability' => account_user&.availability
      }
    end
    exact_candidates = candidates.select { |candidate| exact?(query, candidate['name'], candidate['email']) }
    search_response(tool_context, reference: reference, query: query, candidates: candidates, exact_candidates: exact_candidates)
  end
end
