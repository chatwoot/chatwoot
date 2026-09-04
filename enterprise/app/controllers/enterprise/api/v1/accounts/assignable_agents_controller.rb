module Enterprise::Api::V1::Accounts::AssignableAgentsController
  def index
    super
    return unless @include_ai_assignees

    assistants = @inboxes.filter_map(&:captain_assistant)
    @captain_assistants = assistants.uniq if assistants.size == @inboxes.size && assistants.uniq.one?
  end
end
