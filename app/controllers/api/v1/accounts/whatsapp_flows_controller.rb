class Api::V1::Accounts::WhatsappFlowsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :fetch_whatsapp_flow, only: [:show, :update, :destroy, :publish, :deprecate, :sync, :preview]

  def index
    @whatsapp_flows = Current.account.whatsapp_flows
    @whatsapp_flows = @whatsapp_flows.by_inbox(params[:inbox_id]) if params[:inbox_id].present?
    @whatsapp_flows = @whatsapp_flows.order(updated_at: :desc)
    render json: @whatsapp_flows
  end

  def show
    render json: @whatsapp_flow
  end

  def create
    @whatsapp_flow = Current.account.whatsapp_flows.new(whatsapp_flow_params)
    @whatsapp_flow.created_by = Current.user
    @whatsapp_flow.save!

    # Create on Meta if inbox is present
    if @whatsapp_flow.inbox.present?
      result = Whatsapp::FlowService.new(whatsapp_flow: @whatsapp_flow).create
      unless result[:success]
        error_msg = result[:error]
        @whatsapp_flow.destroy!
        return render json: { error: error_msg }, status: :unprocessable_entity
      end
    end

    render json: @whatsapp_flow, status: :created
  end

  def update
    return render json: { error: 'Published flows cannot be edited' }, status: :unprocessable_entity unless @whatsapp_flow.can_edit?

    @whatsapp_flow.update!(whatsapp_flow_params)

    # Upload updated JSON to Meta if flow exists on Meta
    if @whatsapp_flow.flow_id.present? && @whatsapp_flow.screens.any?
      result = Whatsapp::FlowService.new(whatsapp_flow: @whatsapp_flow).upload_flow_json
      unless result[:success]
        return render json: { error: result[:error], validation_errors: @whatsapp_flow.validation_errors }, status: :unprocessable_entity
      end
    end

    render json: @whatsapp_flow
  end

  def destroy
    result = Whatsapp::FlowService.new(whatsapp_flow: @whatsapp_flow).delete
    return render json: { error: result[:error] }, status: :unprocessable_entity unless result[:success]

    head :ok
  end

  def publish
    result = Whatsapp::FlowService.new(whatsapp_flow: @whatsapp_flow).publish
    return render json: { error: result[:error] }, status: :unprocessable_entity unless result[:success]

    render json: @whatsapp_flow
  end

  def deprecate
    result = Whatsapp::FlowService.new(whatsapp_flow: @whatsapp_flow).deprecate
    return render json: { error: result[:error] }, status: :unprocessable_entity unless result[:success]

    render json: @whatsapp_flow
  end

  def sync
    result = Whatsapp::FlowService.new(whatsapp_flow: @whatsapp_flow).sync
    return render json: { error: result[:error] }, status: :unprocessable_entity unless result[:success]

    render json: @whatsapp_flow
  end

  def preview
    result = Whatsapp::FlowService.new(whatsapp_flow: @whatsapp_flow).preview
    return render json: { error: result[:error] }, status: :unprocessable_entity unless result[:success]

    render json: { preview_url: result[:preview_url] }
  end

  private

  def fetch_whatsapp_flow
    @whatsapp_flow = Current.account.whatsapp_flows.find(params[:id])
  end

  def whatsapp_flow_params
    params.require(:whatsapp_flow).permit(
      :name, :inbox_id,
      categories: [],
      flow_json: {},
      endpoint_uri: {}
    )
  end
end
