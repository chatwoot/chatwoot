class Api::V1::Accounts::WhatsappInteractivePresetsController < Api::V1::Accounts::BaseController
  before_action :check_authorization, only: [:index, :create]
  before_action :fetch_preset, only: [:show, :update, :destroy]
  before_action :authorize_preset, only: [:show, :update, :destroy]

  def index
    @whatsapp_interactive_presets = Current.account.whatsapp_interactive_presets.active.includes(
      { created_by: :account_users }, media: { file_attachment: :blob }
    )
    @whatsapp_interactive_presets = @whatsapp_interactive_presets.search_by_name(params[:search]) if params[:search].present?
    @whatsapp_interactive_presets = @whatsapp_interactive_presets.order(:name, :id)
  end

  def show; end

  def create
    return render_unsupported_fields if unsupported_fields.present?

    WhatsappInteractivePreset.transaction do
      @whatsapp_interactive_preset = Current.account.whatsapp_interactive_presets.create!(
        preset_params.merge(created_by: Current.user)
      )
      Whatsapp::InteractiveMessages::PresetMedia.sync!(@whatsapp_interactive_preset, attachments: attachments_param)
    end
  rescue Whatsapp::InteractiveMessages::ValidationError => e
    render_could_not_create_error(e.message)
  end

  def update
    return render_unsupported_fields if unsupported_fields.present?

    WhatsappInteractivePreset.transaction do
      @whatsapp_interactive_preset.update!(preset_params)
      Whatsapp::InteractiveMessages::PresetMedia.sync!(@whatsapp_interactive_preset, attachments: attachments_param)
    end
  rescue Whatsapp::InteractiveMessages::ValidationError => e
    render_could_not_create_error(e.message)
  end

  def destroy
    @whatsapp_interactive_preset.destroy!
    head :no_content
  end

  private

  def fetch_preset
    @whatsapp_interactive_preset = Current.account.whatsapp_interactive_presets.active.find(params[:id])
  end

  def authorize_preset
    authorize @whatsapp_interactive_preset
  end

  def preset_params
    params.permit(:name, definition: {})
  end

  def attachments_param
    return unless params.key?(:attachments)

    attachments = params[:attachments]
    raise Whatsapp::InteractiveMessages::ValidationError, 'attachments must be an ordered array' unless attachments.is_a?(Array)

    attachments
  end

  def unsupported_fields
    fields = request.request_parameters.keys.map(&:to_s)
    fields -= ['whatsapp_interactive_preset'] if fields.intersect?(%w[name definition attachments])
    fields - %w[name definition attachments]
  end

  def render_unsupported_fields
    render_could_not_create_error("Unsupported fields: #{unsupported_fields.join(', ')}")
  end
end
