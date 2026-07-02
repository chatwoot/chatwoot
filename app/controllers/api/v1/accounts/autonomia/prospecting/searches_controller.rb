class Api::V1::Accounts::Autonomia::Prospecting::SearchesController < Api::V1::Accounts::Autonomia::Prospecting::BaseController
  def index
    render json: { payload: searches_scope.order(created_at: :desc).limit(50).as_json(include: { leads: { only: [:id, :name, :status] } }) }
  end

  def show
    search = searches_scope.find(params[:id])
    render json: { payload: search.as_json(include: { leads: {} }) }
  end

  def create
    search = searches_scope.create!(search_params.merge(user: Current.user, status: :pending))
    render json: { payload: search }, status: :created
  end

  private

  def search_params
    params.require(:search).permit(:query, :location, :radius, :provider, :requested_limit, categories: [], metadata: {})
  end
end
