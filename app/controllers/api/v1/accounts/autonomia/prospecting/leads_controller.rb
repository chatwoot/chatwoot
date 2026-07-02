class Api::V1::Accounts::Autonomia::Prospecting::LeadsController < Api::V1::Accounts::Autonomia::Prospecting::BaseController
  def index
    render json: { payload: leads_scope.order(created_at: :desc).limit(100) }
  end

  def show
    render json: { payload: leads_scope.find(params[:id]) }
  end
end
