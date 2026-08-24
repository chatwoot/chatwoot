# frozen_string_literal: true

# [whisker] Conversation Flows API — CRUD for flow definitions
class Api::V1::Accounts::ConversationFlowsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :fetch_flow, only: [:show, :update, :destroy, :toggle]

  def index
    @flows = current_account.conversation_flows.order(updated_at: :desc)
  end

  def create
    @flow = current_account.conversation_flows.build(flow_params)
    if @flow.save
      render json: @flow, status: :ok
    else
      render json: { errors: @flow.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @flow.update(flow_params)
      render json: @flow, status: :ok
    else
      render json: { errors: @flow.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @flow.destroy
    head :ok
  end

  def toggle
    @flow.update!(enabled: !@flow.enabled?)
    render json: @flow
  end

  private

  def fetch_flow
    @flow = current_account.conversation_flows.find(params[:id])
  end

  def flow_params
    params.require(:conversation_flow).permit(:name, :description, :enabled, flow_data: {})
  end
end
