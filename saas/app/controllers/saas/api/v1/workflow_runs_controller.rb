# frozen_string_literal: true

class Saas::Api::V1::WorkflowRunsController < Api::V1::Accounts::BaseController
  before_action :set_ai_agent
  before_action :set_workflow_run, only: [:show]

  def index
    @runs = @ai_agent.workflow_runs
                     .order(created_at: :desc)
                     .page(params[:page])
                     .per(params[:per_page] || 20)

    render json: {
      data: @runs.map { |run| run_json(run) },
      meta: { total: @runs.total_count, page: @runs.current_page }
    }
  end

  def show
    render json: run_json(@run, detailed: true)
  end

  private

  def set_ai_agent
    @ai_agent = Current.account.ai_agents.find(params[:ai_agent_id])
    authorize @ai_agent, :show?
  end

  def set_workflow_run
    @run = @ai_agent.workflow_runs.find(params[:id])
  end

  def run_json(run, detailed: false)
    data = {
      id: run.id,
      ai_agent_id: run.ai_agent_id,
      conversation_id: run.conversation_id,
      status: run.status,
      current_node_id: run.current_node_id,
      started_at: run.started_at,
      completed_at: run.completed_at,
      duration_ms: run.duration_ms,
      total_tokens: run.total_tokens,
      created_at: run.created_at
    }

    if detailed
      data[:variables] = run.variables
      data[:messages] = run.messages
      data[:execution_log] = run.execution_log
    end

    data
  end
end
