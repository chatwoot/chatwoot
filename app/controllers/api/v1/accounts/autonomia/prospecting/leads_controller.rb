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

  private

  def filtered_leads_scope
    return leads_scope if params[:list_id].blank?

    lists_scope.find(params[:list_id]).leads
  end

  def lead_payload(lead)
    lead.as_json(
      only: [
        :id, :provider, :provider_place_id, :name, :phone, :website, :address, :city, :state, :country,
        :latitude, :longitude, :rating, :reviews_count, :category, :status, :contact_id, :created_at, :updated_at
      ]
    ).merge(
      contact_status: lead.contact_id.present? ? 'created' : 'pending'
    )
  end

  def contact_payload(contact)
    contact.as_json(only: [:id, :name, :email, :phone_number, :identifier])
  end
end
