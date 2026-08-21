module Enterprise::Api::V1::Accounts::AssignableAgentsController
  def index
    super
    return unless @include_captain

    assistants = @inboxes.filter_map { |inbox| inbox.captain_assistant if inbox.captain_active? }
    @captain_assistants = assistants.uniq if assistants.size == @inboxes.size && assistants.uniq.one?
  end
end
