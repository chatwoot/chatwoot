class Api::V1::Accounts::Inboxes::WhatsappTemplatesController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox
  before_action :check_admin
  before_action :validate_whatsapp_channel

  def create
    template_params = extract_template_params
    service = Whatsapp::TemplateCreatorService.new(@inbox.channel)
    result = service.create_template(template_params)

    if result[:success]
      render json: result, status: :ok
    elsif result[:errors]
      render json: { errors: result[:errors] }, status: :unprocessable_entity
    else
      render json: { error: result[:error], response_code: result[:response_code] }, status: :unprocessable_entity
    end
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @inbox, :show?
  end

  def check_admin
    authorize @inbox, :create_whatsapp_template?
  end

  def validate_whatsapp_channel
    return if @inbox.whatsapp?

    render json: { error: 'Template creation is only available for WhatsApp Cloud channels' }, status: :bad_request
  end

  def extract_template_params
    permitted = params.require(:template).permit(:name, :category, :language, :header_text, :body_text, :footer_text, buttons: %i[type text])
    permitted.to_h.deep_symbolize_keys
  end
end
