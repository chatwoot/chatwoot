class Api::V1::Accounts::Autonomia::Prospecting::ListsController < Api::V1::Accounts::Autonomia::Prospecting::BaseController
  def index
    render json: { payload: lists_scope.order(created_at: :desc).limit(100).map { |list| list_payload(list) } }
  end

  def show
    list = lists_scope.find(params[:id])
    render json: { payload: list_payload(list, include_leads: true) }
  end

  def create
    list = lists_scope.create!(list_params.merge(user: Current.user))
    render json: { payload: list_payload(list) }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  def add_lead
    list = lists_scope.find(params[:id])
    lead = leads_scope.find(params.require(:lead_id))
    list_lead = list.list_leads.find_or_initialize_by(lead: lead)
    was_new = list_lead.new_record?
    list_lead.account = Current.account
    list_lead.save!
    lead.ready_for_campaign! unless lead.ready_for_campaign?

    render json: { payload: list_payload(list.reload, include_leads: true) }, status: was_new ? :created : :ok
  rescue ActionController::ParameterMissing => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  def remove_lead
    list = lists_scope.find(params[:id])
    list.list_leads.where(prospect_lead_id: params[:lead_id]).destroy_all

    render json: { payload: list_payload(list.reload, include_leads: true) }
  end

  def campaign_segment
    result = ::Autonomia::Prospecting::CampaignSegmentBuilder.new(
      list: lists_scope.find(params[:id]),
      user: Current.user,
      campaign_id: campaign_segment_params[:campaign_id],
      segment_name: campaign_segment_params[:segment_name]
    ).perform

    render json: {
      payload: {
        list: list_payload(result.list, include_leads: true),
        segment: campaign_segment_payload(result)
      }
    }, status: :created
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'prospecting.campaign.not_found' }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  rescue ::Autonomia::Prospecting::CampaignSegmentBuilder::Error => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def list_params
    params.require(:list).permit(:name, :description, metadata: {})
  end

  def campaign_segment_params
    return {} if params[:campaign_segment].blank?

    params.require(:campaign_segment).permit(:campaign_id, :segment_name)
  end

  def list_payload(list, include_leads: false)
    payload = list.as_json(
      only: [:id, :name, :description, :status, :metadata, :created_at, :updated_at]
    ).merge(
      lead_ids: list.leads.pluck(:id),
      leads_count: list.leads.count,
      campaign_segment: list.metadata.to_h['campaign_segment']
    )

    return payload unless include_leads

    payload.merge(
      leads: list.leads.order(created_at: :desc).map { |lead| lead_payload(lead) }
    )
  end

  def lead_payload(lead)
    lead.as_json(
      only: [
        :id, :provider, :provider_place_id, :name, :phone, :website, :address, :city, :state, :country,
        :latitude, :longitude, :rating, :reviews_count, :category, :status, :discard_reason,
        :score, :priority_score, :priority_position, :search_rank, :score_breakdown, :negative_factors, :human_insight,
        :contact_id, :crm_card_id, :created_at, :updated_at
      ]
    ).merge(
      source_label: lead.provider.to_s.humanize,
      contact_status: lead.contact_id.present? ? 'created' : 'pending',
      crm_status: lead.crm_card_id.present? ? 'created' : 'pending'
    )
  end

  def campaign_segment_payload(result)
    {
      label: {
        id: result.label.id,
        title: result.label.title
      },
      campaign: result.campaign && {
        id: result.campaign.display_id,
        title: result.campaign.title
      },
      eligible_count: result.eligible_leads.size,
      blocked_count: result.blocked_leads.size,
      created_contacts_count: result.created_contacts_count,
      blocked_leads: result.blocked_leads.map do |lead|
        {
          id: lead.id,
          name: lead.name,
          status: lead.status
        }
      end
    }
  end
end
