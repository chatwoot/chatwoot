class Api::V1::Accounts::Conversations::AssignmentsController < Api::V1::Accounts::Conversations::BaseController
  # assigns agent/team to a conversation
  def create
    if params.key?(:assignee_id) || agent_bot_assignment?
      set_agent
    elsif params.key?(:team_id)
      set_team
    elsif params.key?(:location_id)
      set_location
    else
      render json: nil
    end
  end

  private

  def set_agent
    resource = Conversations::AssignmentService.new(
      conversation: @conversation,
      assignee_id: params[:assignee_id],
      assignee_type: params[:assignee_type]
    ).perform

    @agent = resource if resource.is_a?(User)
    trigger_whatsapp_group_creation(resource)
    render_agent(resource)
  end

  def render_agent(resource)
    case resource
    when User
      render partial: 'api/v1/models/agent', formats: [:json], locals: { resource: resource }
    when AgentBot
      render partial: 'api/v1/models/agent_bot_slim', formats: [:json], locals: { resource: resource }
    else
      render json: nil
    end
  end

  def set_team
    @team = Current.account.teams.find_by(id: params[:team_id])
    @conversation.update!(team: @team)
    render json: @team
  end

  def set_location
    @location = Current.account.locations.find_by(id: params[:location_id])
    @conversation.update!(location: @location)
    render json: @location
  end

  def agent_bot_assignment?
    params[:assignee_type].to_s == 'AgentBot'
  end

  def trigger_whatsapp_group_creation(resource)
    return unless whatsapp_group_enabled?
    return unless resource.present?

    group_options = {
      group_name: params[:group_name],
      welcome_message: params[:welcome_message]
    }.compact

    Whatsapp::CreateGroupJob.perform_later(@conversation.id, group_options)
  end

  def whatsapp_group_enabled?
    return false if agent_bot_assignment?
    return false unless Current.account.feature_enabled?(:whatsapp_groups)

    @conversation.inbox.auto_assignment_config&.dig('assignment_type') == 'group' &&
      @agent.phone_number.present? &&
      @conversation.contact&.phone_number.present?
  end
end
