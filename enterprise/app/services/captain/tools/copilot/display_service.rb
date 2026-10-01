class Captain::Tools::Copilot::DisplayService < Captain::Tools::Copilot::WorkflowTool
  def self.name
    'display'
  end
  description 'Read saved review findings as a paginated table with conversation links and coverage. Use content verbatim in the chat response.'
  parameter :run_id, type: :integer, description: 'Review run ID'
  parameter :page, type: :integer, description: 'Result page starting at 1', required: false
  parameter :attention_only, type: :boolean, description: 'Only show findings that need attention', required: false

  def execute(run_id:, page: 1, attention_only: false)
    Captain::Copilot::PresentationService.new(saved_run(run_id, 'review')).table(page: page, attention_only: attention_only)
  end
end
