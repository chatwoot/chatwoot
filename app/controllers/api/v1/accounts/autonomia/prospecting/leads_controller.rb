class Api::V1::Accounts::Autonomia::Prospecting::LeadsController < Api::V1::Accounts::Autonomia::Prospecting::BaseController
  def index
    render json: { payload: filtered_leads_scope.order(created_at: :desc).limit(100).map { |lead| lead_payload(lead) } }
  end

  def show
    render json: { payload: lead_payload(leads_scope.find(params[:id])) }
  end

  def create_contact
    result = ::Autonomia::Prospecting::ContactConverter.new(
      lead: leads_scope.find(params[:id]),
      user: Current.user
    ).perform

    render json: {
      payload: {
        lead: lead_payload(result.lead),
        contact: contact_payload(result.contact),
        created: result.created
      }
    }, status: result.created ? :created : :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  def create_crm_card
    result = ::Autonomia::Prospecting::CrmCardConverter.new(
      lead: leads_scope.find(params[:id]),
      user: Current.user,
      pipeline_id: crm_card_params.require(:pipeline_id),
      stage_id: crm_card_params.require(:stage_id)
    ).perform

    render json: {
      payload: {
        lead: lead_payload(result.lead),
        crm_card: crm_card_payload(result.card),
        created: result.created
      }
    }, status: result.created ? :created : :ok
  rescue ActionController::ParameterMissing => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'crm.pipeline_or_stage_not_found' }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  rescue ::Autonomia::Prospecting::CrmCardConverter::Error => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def filtered_leads_scope
    return leads_scope if params[:list_id].blank?

    lists_scope.find(params[:list_id]).leads
  end

  def lead_payload(lead)
    lead.as_json(
      only: [
        :id, :provider, :provider_place_id, :name, :phone, :website, :address, :city, :state, :country,
        :latitude, :longitude, :rating, :reviews_count, :category, :status, :contact_id, :crm_card_id, :created_at, :updated_at
      ]
    ).merge(
      contact_status: lead.contact_id.present? ? 'created' : 'pending',
      crm_status: lead.crm_card_id.present? ? 'created' : 'pending'
    )
  end

  def contact_payload(contact)
    contact.as_json(only: [:id, :name, :email, :phone_number, :identifier])
  end

  def crm_card_payload(card)
    card.as_json(
      only: [:id, :title, :pipeline_id, :stage_id, :contact_id, :status, :source, :created_at, :updated_at]
    )
  end

  def crm_card_params
    params.require(:crm_card).permit(:pipeline_id, :stage_id)
  end
end
