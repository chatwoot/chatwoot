class Api::V1::Accounts::Inboxes::WhatsappTemplatesController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox
  before_action :validate_whatsapp_cloud_channel

  def index
    result = template_service.list
    if result[:success]
      render json: { templates: result[:templates] }
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  def create
    result = template_service.create(template_params)
    if result[:success]
      trigger_template_sync
      render json: { template: result.except(:success) }, status: :created
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    result = template_service.delete(params[:id])
    if result[:success]
      trigger_template_sync
      render json: { success: true }
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @inbox, :show?
  end

  def validate_whatsapp_cloud_channel
    return if @inbox.whatsapp? && @inbox.channel.provider == 'whatsapp_cloud'

    render json: { error: 'Template management is only available for WhatsApp Cloud channels' },
           status: :bad_request
  end

  def template_service
    @template_service ||= Whatsapp::TemplateManagementService.new(@inbox.channel)
  end

  def trigger_template_sync
    Channels::Whatsapp::TemplatesSyncJob.perform_later(@inbox.channel)
  end

  def template_params
    raw = params.require(:template)
    {
      name: raw[:name],
      category: raw[:category],
      language: raw[:language],
      allow_category_change: raw[:allow_category_change],
      components: raw[:components].map { |c| c.to_unsafe_h.deep_symbolize_keys }
    }.compact
  end
end
