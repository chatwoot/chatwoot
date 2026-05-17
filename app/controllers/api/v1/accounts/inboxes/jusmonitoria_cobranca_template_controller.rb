class Api::V1::Accounts::Inboxes::JusmonitoriaCobrancaTemplateController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox
  before_action :validate_whatsapp_channel
  before_action :check_admin, only: [:create]

  def show
    render json: Whatsapp::JusmonitoriaCobrancaTemplateService.new(@inbox, template_name: params[:template_name]).status
  end

  def create
    render json: Whatsapp::JusmonitoriaCobrancaTemplateService.new(@inbox, template_name: params[:template_name]).create
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @inbox, :show?
  end

  def validate_whatsapp_channel
    return if @inbox.whatsapp?

    render json: { error: 'JusMonitorIA parcela cobranca template is only available for WhatsApp inboxes' }, status: :bad_request
  end

  def check_admin
    authorize @inbox, :create_whatsapp_template?
  end
end
