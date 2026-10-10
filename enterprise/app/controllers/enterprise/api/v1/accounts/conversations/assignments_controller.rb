module Enterprise::Api::V1::Accounts::Conversations::AssignmentsController
  private

  def render_agent(resource)
    return super unless resource.is_a?(Captain::Assistant)

    render partial: 'api/v1/models/captain/assistant_slim', formats: [:json], locals: { resource: resource }
  end
end
