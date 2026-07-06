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
  rescue ::Autonomia::Prospecting::SearchRunner::ProviderError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update
    search = searches_scope.find(params[:id])
    search.update!(metadata: search.metadata.to_h.merge(search_settings_metadata))

    render json: { payload: search_payload(search.reload) }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'crm.pipeline_or_stage_not_found' }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  private

  def search_params
    params.require(:search).permit(:query, :location, :radius, :requested_limit, :limit, :crm_pipeline_id, :crm_stage_id, categories: [], metadata: {})
  end

  def search_update_params
    params.require(:search).permit(:crm_pipeline_id, :crm_stage_id)
  end

  def search_settings_metadata
    attributes = search_update_params.to_h.symbolize_keys
    pipeline_id = attributes[:crm_pipeline_id].presence
    stage_id = attributes[:crm_stage_id].presence
    pipeline = nil
    stage = nil

    if pipeline_id.present? && stage_id.present?
      pipeline = Current.account.crm_pipelines.active.find(pipeline_id)
      stage = Current.account.crm_pipeline_stages.where(pipeline: pipeline).find(stage_id)
    end

    {
      'crm_pipeline_id' => pipeline&.id,
      'crm_stage_id' => stage&.id
    }
  end

  def search_payload(search, include_leads: false)
    payload = search.as_json(
      only: [:id, :query, :location, :radius, :provider, :status, :requested_limit, :created_at, :updated_at]
    )
    lead_ids = Array(search.metadata.to_h['lead_ids'])
    payload['results_count'] = search.metadata.to_h['results_count'] || lead_ids.size || search.leads.count
    payload['crm_pipeline_id'] = search.metadata.to_h['crm_pipeline_id']
    payload['crm_stage_id'] = search.metadata.to_h['crm_stage_id']
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
        :latitude, :longitude, :rating, :reviews_count, :category, :status, :discard_reason,
        :contact_id, :crm_card_id, :created_at, :updated_at
      ]
    ).merge(
      source_label: lead.provider.to_s.humanize,
      contact_status: lead.contact_id.present? ? 'created' : 'pending',
      crm_status: lead.crm_card_id.present? ? 'created' : 'pending'
    )
  end
end
