class Api::V1::Accounts::Autonomia::Prospecting::LeadsController < Api::V1::Accounts::Autonomia::Prospecting::BaseController
  def index
    render json: { payload: leads_scope.order(created_at: :desc).limit(100).map { |lead| lead_payload(lead) } }
  end

  def show
    render json: { payload: lead_payload(leads_scope.find(params[:id])) }
  end

  private

  def lead_payload(lead)
    lead.as_json(
      only: [
        :id, :provider, :provider_place_id, :name, :phone, :website, :address, :city, :state, :country,
        :latitude, :longitude, :rating, :reviews_count, :category, :status, :created_at, :updated_at
      ]
    )
  end
end
