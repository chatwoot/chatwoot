# frozen_string_literal: true

class Saas::Api::V1::AgentToolsController < Api::V1::Accounts::BaseController
  before_action :set_ai_agent
  before_action :set_tool, only: [:update, :destroy]

  def index
    @tools = @ai_agent.agent_tools.order(:name)
    render json: @tools.map { |t| tool_json(t) }
  end

  def create
    @tool = @ai_agent.agent_tools.new(tool_params.merge(account: Current.account))
    if @tool.save
      render json: tool_json(@tool), status: :created
    else
      render json: { errors: @tool.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @tool.update(tool_params)
      render json: tool_json(@tool)
    else
      render json: { errors: @tool.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @tool.destroy!
    head :no_content
  end

  private

  def set_ai_agent
    @ai_agent = Current.account.ai_agents.find(params[:ai_agent_id])
  end

  def set_tool
    @tool = @ai_agent.agent_tools.find(params[:id])
  end

  def tool_params
    params.require(:agent_tool).permit(
      :name, :description, :tool_type, :http_method, :url_template,
      :body_template, :auth_type, :auth_token, :active,
      headers_template: {},
      parameters_schema: {},
      config: {}
    )
  end

  def tool_json(tool)
    { id: tool.id, name: tool.name, description: tool.description, tool_type: tool.tool_type,
      http_method: tool.http_method, url_template: tool.url_template, body_template: tool.body_template,
      headers_template: tool.headers_template, parameters_schema: tool.parameters_schema,
      auth_type: tool.auth_type, active: tool.active, config: tool.config,
      created_at: tool.created_at, updated_at: tool.updated_at }
  end
end
