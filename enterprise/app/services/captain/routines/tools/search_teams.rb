class Captain::Routines::Tools::SearchTeams < Captain::Routines::Tools::Base
  description 'Search live teams in the Routine account by partial name and pin a unique match as a resource'
  param :reference, type: 'string', desc: 'Stable snake_case resource name, for example engineering_team'
  param :query, type: 'string', desc: 'Team name from the administrator instruction'

  def name = 'search_teams'

  def perform(tool_context, reference:, query:)
    candidates = account(tool_context).teams
                                      .where('teams.name ILIKE ?', search_term(query))
                                      .order(:name, :id)
                                      .limit(10)
                                      .map { |team| { 'type' => 'team', 'id' => team.id, 'name' => team.name } }
    exact_candidates = candidates.select { |candidate| exact?(query, candidate['name']) }
    search_response(tool_context, reference: reference, query: query, candidates: candidates, exact_candidates: exact_candidates)
  end
end
