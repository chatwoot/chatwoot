class Captain::Workflows::Nodes::AssignTeamNode < Captain::Workflows::Nodes::BaseNode
  def execute
    team_id = node_data['team_id']
    conversation.update!(team_id: team_id)
    { team_id: team_id }
  end
end
