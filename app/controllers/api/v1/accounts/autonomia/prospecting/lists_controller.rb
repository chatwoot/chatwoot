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

  private

  def list_params
    params.require(:list).permit(:name, :description, metadata: {})
  end

  def list_payload(list, include_leads: false)
    payload = list.as_json(
      only: [:id, :name, :description, :status, :created_at, :updated_at]
    ).merge(
      lead_ids: list.leads.pluck(:id),
      leads_count: list.leads.count
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
        :contact_id, :crm_card_id, :created_at, :updated_at
      ]
    ).merge(
      source_label: lead.provider.to_s.humanize,
      contact_status: lead.contact_id.present? ? 'created' : 'pending',
      crm_status: lead.crm_card_id.present? ? 'created' : 'pending'
    )
  end
end
