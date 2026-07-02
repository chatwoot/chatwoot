class Api::V1::Accounts::Autonomia::Prospecting::ListsController < Api::V1::Accounts::Autonomia::Prospecting::BaseController
  def index
    render json: { payload: lists_scope.order(created_at: :desc).limit(100).as_json(methods: [:lead_ids]) }
  end

  def show
    list = lists_scope.find(params[:id])
    render json: { payload: list.as_json(include: { leads: {} }) }
  end

  def create
    list = lists_scope.create!(list_params.merge(user: Current.user))
    render json: { payload: list }, status: :created
  end

  private

  def list_params
    params.require(:list).permit(:name, :description, metadata: {})
  end
end
