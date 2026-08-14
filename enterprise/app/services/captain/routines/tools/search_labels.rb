class Captain::Routines::Tools::SearchLabels < Captain::Routines::Tools::Base
  description 'Search live labels in the Routine account by partial title and pin a unique match as a resource'
  param :reference, type: 'string', desc: 'Stable snake_case resource name, for example urgent_label'
  param :query, type: 'string', desc: 'Label title from the administrator instruction'

  def name = 'search_labels'

  def perform(tool_context, reference:, query:)
    candidates = account(tool_context).labels
                                      .where('labels.title ILIKE ?', search_term(query))
                                      .order(:title, :id)
                                      .limit(10)
                                      .map do |label|
      {
        'type' => 'label', 'id' => label.id, 'name' => label.title,
        'description' => label.description, 'color' => label.color
      }
    end
    exact_candidates = candidates.select { |candidate| exact?(query, candidate['name']) }
    search_response(tool_context, reference: reference, query: query, candidates: candidates, exact_candidates: exact_candidates)
  end
end
