class Api::V1::Accounts::ConversationSalesStagesController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :fetch_conversation
  before_action :check_authorization

  def show
    stage_manager = SalesPipeline::ConversationStageManager.new(
      conversation: @conversation,
      account: current_account
    )
    @current_stage = stage_manager.current_stage
  end

  def update
    stage_manager = SalesPipeline::ConversationStageManager.new(
      conversation: @conversation,
      account: current_account
    )

    stage = current_account.sales_pipeline_stages.find(stage_params[:stage_id])
    stage_manager.update_stage!(stage)

    @current_stage = stage
  end

  def destroy
    stage_manager = SalesPipeline::ConversationStageManager.new(
      conversation: @conversation,
      account: current_account
    )

    stage_manager.remove_stage!
    head :ok
  end

  private

  def fetch_conversation
    @conversation = current_account.conversations.find(params[:conversation_id])
  end

  def stage_params
    params.require(:sales_stage).permit(:stage_id)
  end
end