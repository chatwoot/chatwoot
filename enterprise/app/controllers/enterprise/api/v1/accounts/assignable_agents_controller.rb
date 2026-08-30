module Enterprise::Api::V1::Accounts::AssignableAgentsController
  def index
    super
    return unless @include_ai_assignees

    assistants = @inboxes.filter_map { |inbox| inbox.captain_assistant if captain_assignable?(inbox) }
    @captain_assistants = assistants.uniq if assistants.size == @inboxes.size && assistants.uniq.one?
  end

  private

  def captain_assignable?(inbox)
    inbox.captain_active? && !inbox.external_bot_active?
  end
end
