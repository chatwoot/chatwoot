class Api::V1::Accounts::Autonomia::Prospecting::SearchesController < Api::V1::Accounts::Autonomia::Prospecting::BaseController
  AUTOCOMPLETE_ENDPOINT = 'https://places.googleapis.com/v1/places:autocomplete'.freeze
  PLACE_DETAILS_ENDPOINT = 'https://places.googleapis.com/v1/places'.freeze

  def index
    searches = searches_scope.order(created_at: :desc).limit(50)
    render json: { payload: searches.map { |search| search_payload(search) } }
  end

  def location_suggestions
    query = params[:query].to_s.strip
    return render json: { payload: [] } if query.length < 3

    setting = ::Autonomia::Prospecting::Config.for_account(Current.account)
    return render json: { payload: [] } unless setting.google_places_configured?

    render json: { payload: google_place_predictions(query, setting.google_places_api_key) }
  rescue StandardError
    render json: { payload: [] }
  end

  def location_details
    place_id = params[:place_id].to_s.strip
    return render json: { payload: {} } if place_id.blank?

    setting = ::Autonomia::Prospecting::Config.for_account(Current.account)
    return render json: { payload: {} } unless setting.google_places_configured?

    render json: { payload: google_place_details(place_id, setting.google_places_api_key) }
  rescue StandardError
    render json: { payload: {} }
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

  def destroy
    search = searches_scope.find(params[:id])
    search.destroy!

    render json: { payload: { id: search.id } }
  end

  private

  def search_params
    params.require(:search).permit(
      :query,
      :location,
      :radius,
      :requested_limit,
      :limit,
      :crm_pipeline_id,
      :crm_stage_id,
      categories: [],
      metadata: [
        :location_place_id,
        :location_latitude,
        :location_longitude,
        :location_label
      ]
    )
  end

  def search_update_params
    params.require(:search).permit(:crm_pipeline_id, :crm_stage_id)
  end

  def google_place_predictions(query, api_key)
    uri = URI(AUTOCOMPLETE_ENDPOINT)
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['X-Goog-Api-Key'] = api_key
    request['X-Goog-FieldMask'] = [
      'suggestions.placePrediction.text',
      'suggestions.placePrediction.placeId'
    ].join(',')
    request.body = {
      input: query,
      includedPrimaryTypes: [
        'locality',
        'sublocality',
        'administrative_area_level_2'
      ]
    }.to_json

    response = Net::HTTP.start(
      uri.hostname,
      uri.port,
      use_ssl: true,
      read_timeout: 8
    ) do |http|
      http.request(request)
    end
    return [] unless response.is_a?(Net::HTTPSuccess)

    Array(JSON.parse(response.body)['suggestions'])
      .filter_map do |item|
        prediction = item['placePrediction']
        text = prediction&.dig('text', 'text')
        place_id = prediction&.dig('placeId')
        next if text.blank? || place_id.blank?

        { text: text, place_id: place_id }
      end
      .uniq { |item| item[:place_id] }
      .first(8)
  end

  def google_place_details(place_id, api_key)
    uri = URI("#{PLACE_DETAILS_ENDPOINT}/#{place_id}")
    request = Net::HTTP::Get.new(uri)
    request['X-Goog-Api-Key'] = api_key
    request['X-Goog-FieldMask'] = 'id,displayName,formattedAddress,location'

    response = Net::HTTP.start(
      uri.hostname,
      uri.port,
      use_ssl: true,
      read_timeout: 8
    ) do |http|
      http.request(request)
    end
    return {} unless response.is_a?(Net::HTTPSuccess)

    body = JSON.parse(response.body)
    {
      place_id: body['id'],
      label: body['formattedAddress'].presence || body.dig('displayName', 'text'),
      latitude: body.dig('location', 'latitude'),
      longitude: body.dig('location', 'longitude')
    }
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
      only: [
        :id, :query, :location, :radius, :provider, :status, :requested_limit, :created_at, :updated_at
      ]
    )
    lead_ids = Array(search.metadata.to_h['lead_ids'])
    leads = leads_for_search(search)
    payload['results_count'] =
      if search.metadata.to_h.key?('results_count')
        search.metadata.to_h['results_count']
      elsif lead_ids.present?
        lead_ids.size
      else
        leads.count
      end
    payload['crm_pipeline_id'] = search.metadata.to_h['crm_pipeline_id']
    payload['crm_stage_id'] = search.metadata.to_h['crm_stage_id']
    payload['crm_count'] = leads.count { |lead| lead.crm_card_id.present? }
    payload['contact_count'] = leads.count { |lead| lead.contact_id.present? }
    payload['location_place_id'] = search.metadata.to_h['location_place_id']
    payload['location_latitude'] = search.metadata.to_h['location_latitude']
    payload['location_longitude'] = search.metadata.to_h['location_longitude']
    payload['location_label'] = search.metadata.to_h['location_label']
    payload['leads'] = leads.map { |lead| lead_payload(lead) } if include_leads
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
