# frozen_string_literal: true

class Api::V1::Accounts::Whatsapp::MessageTemplatesController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox
  before_action :validate_whatsapp_cloud_channel

  def index
    templates = @inbox.message_templates || []
    render json: { templates: templates }
  end

  def upload_media
    file = params[:file]
    unless file.respond_to?(:original_filename) && file.respond_to?(:content_type) && file.respond_to?(:tempfile)
      return render json: { error: 'Missing file' }, status: :unprocessable_entity
    end

    service = Whatsapp::MessageTemplateService.new(@inbox.channel)
    result = service.upload_template_media(file)

    if result[:success]
      render json: { handle: result[:handle] }, status: :ok
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  def create
    service = Whatsapp::MessageTemplateService.new(@inbox.channel)
    result = service.create_template(template_params.to_h)

    if result[:success]
      render json: result[:template], status: :created
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  def destroy
    service = Whatsapp::MessageTemplateService.new(@inbox.channel)
    result = service.delete_template(params[:name])

    if result[:success]
      render json: { message: 'Template deleted successfully' }
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
    # CommMate: Restrict to WhatsApp Cloud provider only
    return if @inbox.whatsapp? && @inbox.channel.provider == 'whatsapp_cloud'

    render json: { error: 'Template management is only available for WhatsApp Cloud channels' }, status: :unprocessable_entity
  end

  def template_params
    # Meta template API requires complex nested structures that are difficult with strong params
    # We extract the data directly from params to preserve the exact structure
    {
      name: params[:name],
      category: params[:category],
      language: params[:language],
      allow_category_change: params[:allow_category_change],
      components: params[:components]&.map { |c| c.to_unsafe_h.deep_symbolize_keys }
    }.compact
  end
end
