class Api::V1::Accounts::Autonomia::Prospecting::SearchesController < Api::V1::Accounts::Autonomia::Prospecting::BaseController
  def index
    searches = searches_scope.order(created_at: :desc).limit(50)
    render json: { payload: searches.map { |search| search_payload(search) } }
  end

  def show
    search = searches_scope.find(params[:id])
    render json: { payload: search_payload(search, include_leads: true) }
  end

  def create
    result = ::Autonomia::Prospecting::SearchRunner.new(
      account: Current.account,
      user: Current.user,
      params: search_params
    ).perform

    render json: {
      payload: {
        search: search_payload(result.search),
        leads: result.leads.map { |lead| lead_payload(lead) }
      }
    }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  rescue ::Autonomia::Prospecting::SearchRunner::UnsupportedProviderError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def search_params
    params.require(:search).permit(:query, :location, :radius, :provider, :requested_limit, :limit, categories: [], metadata: {})
  end

  def search_payload(search, include_leads: false)
    payload = search.as_json(
      only: [:id, :query, :location, :radius, :provider, :status, :requested_limit, :created_at, :updated_at]
    )
    lead_ids = Array(search.metadata.to_h['lead_ids'])
    payload['results_count'] = search.metadata.to_h['results_count'] || lead_ids.size || search.leads.count
    payload['leads'] = leads_for_search(search).map { |lead| lead_payload(lead) } if include_leads
    payload
  end

  def leads_for_search(search)
    lead_ids = Array(search.metadata.to_h['lead_ids']).map(&:to_i)
    return search.leads.order(created_at: :desc) if lead_ids.blank?

    leads_scope.where(id: lead_ids).index_by(&:id).values_at(*lead_ids).compact
  end

  def lead_payload(lead)
    lead.as_json(
      only: [
        :id, :provider, :provider_place_id, :name, :phone, :website, :address, :city, :state, :country,
        :latitude, :longitude, :rating, :reviews_count, :category, :status, :created_at, :updated_at
      ]
    )
  end
end
