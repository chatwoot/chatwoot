class Api::V1::Accounts::InsightsController < Api::V1::Accounts::BaseController
  before_action :fetch_insight, only: [:show, :update, :destroy]

  def index
    @insights = Current.account.insights.latest
  end

  def show
  end

  def create
    @insight = Current.account.insights.new(insight_params)
    @insight.user = current_user
    authorize @insight
    @insight.save!
    render :show
  end

  def update
    @insight.update!(insight_params)
    render :show
  end

  def destroy
    @insight.destroy!
    head :ok
  end

  private

  def insight_params
    params.require(:insight).permit(:name, :config)
  end

  def fetch_insight
    @insight = Current.account.insights.find(params[:id])
    authorize @insight
  end
end
