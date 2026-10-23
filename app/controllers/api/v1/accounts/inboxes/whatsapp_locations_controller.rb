class Api::V1::Accounts::Inboxes::WhatsappLocationsController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox
  before_action :ensure_whatsapp_cloud_inbox
  before_action :validate_locations_param

  def update
    @inbox.channel.update!(locations: locations_params)
    render json: { locations: @inbox.channel.locations }
  rescue ActiveRecord::RecordInvalid => e
    render_could_not_create_error(e.record.errors.full_messages.to_sentence)
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @inbox, :update?
  end

  def ensure_whatsapp_cloud_inbox
    channel = @inbox.channel
    return if channel.is_a?(Channel::Whatsapp) && channel.provider == 'whatsapp_cloud'

    render_could_not_create_error(I18n.t('errors.whatsapp.locations.cloud_inbox_required'))
  end

  def validate_locations_param
    return if params[:locations].is_a?(Array) && params[:locations].all?(ActionController::Parameters)

    render_could_not_create_error(I18n.t('errors.whatsapp.locations.invalid_locations'))
  end

  def locations_params
    params.permit(locations: [:id, :name, :address, :latitude, :longitude])[:locations].map do |location|
      location.to_h.merge('id' => location[:id].presence || SecureRandom.uuid)
    end
  end
end
