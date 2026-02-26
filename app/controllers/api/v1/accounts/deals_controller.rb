class Api::V1::Accounts::DealsController < Api::V1::Accounts::BaseController
  before_action :fetch_deal, only: [:show, :update, :destroy]

  def index
    @deals = current_account.deals.includes(:contact, :pipeline_stage)
    @deals = @deals.where(pipeline_stage_id: params[:pipeline_stage_id]) if params[:pipeline_stage_id].present?
    render json: @deals.as_json(include: [:contact, :pipeline_stage])
  end

  def show
    render json: @deal.as_json(include: [:contact, :pipeline_stage, :conversation])
  end

  def create
    @deal = current_account.deals.build(deal_params)
    if @deal.save
      render json: @deal, status: :created
    else
      render json: { errors: @deal.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @deal.update(deal_params)
      render json: @deal
    else
      render json: { errors: @deal.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @deal.destroy
    head :no_content
  end

  private

  def fetch_deal
    @deal = current_account.deals.find(params[:id])
  end

  def deal_params
    params.require(:deal).permit(:name, :value, :status, :contact_id, :pipeline_stage_id, :conversation_id)
  end
end
