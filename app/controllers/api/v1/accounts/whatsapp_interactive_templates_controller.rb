# frozen_string_literal: true

class Api::V1::Accounts::WhatsappInteractiveTemplatesController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :fetch_template, only: [:destroy]

  def index
    @templates = Current.account.whatsapp_interactive_templates.order(created_at: :desc)
    render json: @templates
  end

  def create
    payload = Whatsapp::InteractiveTemplatePayloadBuilder.new(
      template_attributes: permitted_params.to_h
    ).build_template_payload

    @template = Current.account.whatsapp_interactive_templates.create!(
      permitted_params.merge(payload: payload)
    )

    render json: @template, status: :created
  rescue Whatsapp::InteractiveTemplatePayloadBuilder::ValidationError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    @template.destroy!
    head :ok
  end

  def publish_header
    blob = ActiveStorage::Blob.find_signed(params[:blob_id].to_s)
    file_url = Whatsapp::InteractiveHeaderPublisherService.new(blob: blob).perform

    render json: { file_url: file_url }
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
    render json: { error: 'Invalid blob id' }, status: :unprocessable_entity
  rescue Whatsapp::InteractiveHeaderPublisherService::PublishError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def fetch_template
    @template = Current.account.whatsapp_interactive_templates.find(params[:id])
  end

  def permitted_params
    params.require(:whatsapp_interactive_template).permit(
      :name,
      :template_type,
      :header_type,
      :header_text,
      :header_image_url,
      :body_text,
      :footer_text,
      :button_text,
      :url_placeholder
    )
  end
end
