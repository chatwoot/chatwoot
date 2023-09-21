module Enterprise::Api::V1::Accounts::InboxesController
  def response_sources
    @response_sources = @inbox.response_sources
  end

  def inbox_attributes
    super + ee_inbox_attributes
  end

  def ee_inbox_attributes
    [auto_assignment_config: [:max_assignment_limit]]
  end
end
