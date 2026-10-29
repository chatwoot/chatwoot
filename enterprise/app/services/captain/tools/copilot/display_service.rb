class Captain::Tools::Copilot::DisplayService < Captain::Tools::Copilot::WorkflowTool
  def self.name
    'display'
  end
  description 'Read a saved collection or review findings as a paginated table with links and coverage. Use the table verbatim in the chat ' \
              "response. With messages, read a conversation collection's first and latest customer messages instead. They are for " \
              'you to read before deciding on a review, not to repeat in the chat response.'
  parameter :saved_set_id, type: :integer, description: 'ID of a collection or review'
  parameter :page, type: :integer, description: 'Result page starting at 1', required: false
  parameter :matched_only, type: :boolean, description: 'For a review, only show findings that matched the criteria', required: false
  parameter :messages, type: :boolean, description: 'For a conversation collection, show customer messages instead of the table', required: false

  def execute(saved_set_id:, page: 1, matched_only: false, messages: false)
    saved_set = run.copilot_thread.saved_set(saved_set_id)
    return Captain::Copilot::MessagesView.new(saved_set).page(page) if messages

    Captain::Copilot::ResultTable.new(saved_set).page(page, matched_only: matched_only)
  end
end
