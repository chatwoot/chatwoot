class Captain::Tools::Copilot::DisplayService < Captain::Tools::Copilot::WorkflowTool
  def self.name
    'display'
  end
  description 'Read a saved collection or review findings as a paginated table with links and coverage. Use content verbatim in the chat response.'
  parameter :run_id, type: :integer, description: 'Collection or review ID'
  parameter :page, type: :integer, description: 'Result page starting at 1', required: false
  parameter :matched_only, type: :boolean, description: 'For a review, only show findings that matched the criteria', required: false

  def execute(run_id:, page: 1, matched_only: false)
    Captain::Copilot::PresentationService.new(saved_run(run_id, %w[collection review])).table(page: page, matched_only: matched_only)
  end
end
