# API controller for YCloud-specific WhatsApp channel operations.
# All actions require admin access and operate on a specific inbox's YCloud channel.
#
# Exposes management operations for:
# - Templates CRUD
# - WhatsApp Flows CRUD
# - Business profile management
# - Commerce settings
# - WhatsApp Calling
# - Media upload
# - Mark as read / Typing indicators
# - YCloud CRM contacts
# - Custom events
# - Multi-channel messaging (SMS, Email, Voice, Verification)
# - Unsubscriber management
# - Webhook endpoint management
# - Account balance
class Api::V1::Accounts::Channels::Whatsapp::YcloudController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_channel
  before_action :ensure_ycloud_provider

  # --- Templates ---

  # POST /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/templates
  def create_template
    render_result template_service.create(template_params)
  end

  # GET /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/templates
  def list_templates
    render_result template_service.list(page: params[:page] || 1, limit: params[:limit] || 100)
  end

  # GET /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/templates/:name/:language
  def show_template
    render_result template_service.retrieve(params[:name], params[:language])
  end

  # PATCH /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/templates/:name/:language
  def update_template
    render_result template_service.update(params[:name], params[:language], template_params)
  end

  # DELETE /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/templates/:name(/:language)
  def delete_template
    if params[:language].present?
      render_result template_service.delete(params[:name], params[:language])
    else
      render_result template_service.delete_all(params[:name])
    end
  end

  # --- Flows ---

  # POST /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/flows
  def create_flow
    render_result flow_service.create(flow_params)
  end

  # GET /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/flows
  def list_flows
    render_result flow_service.list(page: params[:page] || 1, limit: params[:limit] || 20)
  end

  # GET /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/flows/:flow_id
  def show_flow
    render_result flow_service.retrieve(params[:flow_id])
  end

  # PATCH /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/flows/:flow_id/metadata
  def update_flow_metadata
    render_result flow_service.update_metadata(params[:flow_id], flow_params)
  end

  # PATCH /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/flows/:flow_id/structure
  def update_flow_structure
    render_result flow_service.update_structure(params[:flow_id], flow_params)
  end

  # DELETE /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/flows/:flow_id
  def delete_flow
    render_result flow_service.delete(params[:flow_id])
  end

  # POST /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/flows/:flow_id/publish
  def publish_flow
    render_result flow_service.publish(params[:flow_id])
  end

  # POST /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/flows/:flow_id/deprecate
  def deprecate_flow
    render_result flow_service.deprecate(params[:flow_id])
  end

  # GET /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/flows/:flow_id/preview
  def preview_flow
    render_result flow_service.preview(params[:flow_id])
  end

  # --- Business Profile ---

  # GET /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/profile
  def show_profile
    phone_number_id = params[:phone_number_id] || @channel.provider_config['phone_number_id']
    render_result profile_service.get_business_profile(phone_number_id)
  end

  # PATCH /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/profile
  def update_profile
    phone_number_id = params[:phone_number_id] || @channel.provider_config['phone_number_id']
    render_result profile_service.update_business_profile(phone_number_id, profile_params)
  end

  # GET /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/phone_numbers
  def list_phone_numbers
    render_result profile_service.list_phone_numbers(page: params[:page] || 1, limit: params[:limit] || 20)
  end

  # GET /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/commerce_settings
  def show_commerce_settings
    phone_number_id = params[:phone_number_id] || @channel.provider_config['phone_number_id']
    render_result profile_service.get_commerce_settings(phone_number_id)
  end

  # PATCH /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/commerce_settings
  def update_commerce_settings
    phone_number_id = params[:phone_number_id] || @channel.provider_config['phone_number_id']
    render_result profile_service.update_commerce_settings(phone_number_id, commerce_params)
  end

  # --- Calling ---

  # POST /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/calls/connect
  def connect_call
    render_result call_service.connect(call_params)
  end

  # POST /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/calls/pre_accept
  def pre_accept_call
    render_result call_service.pre_accept(call_params)
  end

  # POST /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/calls/accept
  def accept_call
    render_result call_service.accept(call_params)
  end

  # POST /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/calls/terminate
  def terminate_call
    render_result call_service.terminate(call_params)
  end

  # POST /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/calls/reject
  def reject_call
    render_result call_service.reject(call_params)
  end

  # --- Messaging Actions ---

  # POST /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/mark_as_read
  def mark_as_read
    render_result provider_service.mark_as_read(params[:message_id])
  end

  # POST /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/typing_indicator
  def typing_indicator
    render_result provider_service.send_typing_indicator(params[:phone_number])
  end

  # POST /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/upload_media
  def upload_media
    file = params[:file]
    content_type = params[:content_type] || file&.content_type
    result = provider_service.upload_media(file, content_type)
    if result
      render json: { media_id: result }
    else
      render json: { error: 'Upload failed' }, status: :unprocessable_entity
    end
  end

  # --- YCloud CRM Contacts ---

  # POST /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/ycloud_contacts
  def create_ycloud_contact
    render_result contact_service.create(ycloud_contact_params)
  end

  # GET /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/ycloud_contacts
  def list_ycloud_contacts
    render_result contact_service.list(page: params[:page] || 1, limit: params[:limit] || 20)
  end

  # GET /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/ycloud_contacts/:contact_id
  def show_ycloud_contact
    render_result contact_service.retrieve(params[:contact_id])
  end

  # PATCH /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/ycloud_contacts/:contact_id
  def update_ycloud_contact
    render_result contact_service.update(params[:contact_id], ycloud_contact_params)
  end

  # DELETE /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/ycloud_contacts/:contact_id
  def delete_ycloud_contact
    render_result contact_service.delete(params[:contact_id])
  end

  # --- Custom Events ---

  # POST /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/custom_events/definitions
  def create_event_definition
    render_result event_service.create_definition(event_definition_params)
  end

  # POST /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/custom_events
  def send_custom_event
    render_result event_service.send_event(custom_event_params)
  end

  # --- Multi-Channel ---

  # POST /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/sms
  def send_sms
    render_result multi_channel_service.send_sms(sms_params)
  end

  # POST /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/email
  def send_email
    render_result multi_channel_service.send_email(email_params)
  end

  # POST /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/voice
  def send_voice
    render_result multi_channel_service.send_voice(voice_params)
  end

  # POST /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/verification/start
  def start_verification
    render_result multi_channel_service.start_verification(verification_params)
  end

  # POST /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/verification/check
  def check_verification
    render_result multi_channel_service.check_verification(verification_check_params)
  end

  # --- Unsubscribers ---

  # POST /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/unsubscribers
  def create_unsubscriber
    render_result unsubscriber_service.create(unsubscriber_params)
  end

  # GET /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/unsubscribers
  def list_unsubscribers
    render_result unsubscriber_service.list(page: params[:page] || 1, limit: params[:limit] || 20)
  end

  # GET /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/unsubscribers/:customer/:channel
  def check_unsubscriber
    result = unsubscriber_service.check(params[:customer], params[:channel])
    render json: { unsubscribed: result }
  end

  # DELETE /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/unsubscribers/:customer/:channel
  def delete_unsubscriber
    render_result unsubscriber_service.delete(params[:customer], params[:channel])
  end

  # --- Webhook Endpoints ---

  # GET /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/webhook_endpoints
  def list_webhook_endpoints
    render_result webhook_service.list(page: params[:page] || 1, limit: params[:limit] || 20)
  end

  # POST /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/webhook_endpoints/:endpoint_id/rotate_secret
  def rotate_webhook_secret
    render_result webhook_service.rotate_secret(params[:endpoint_id])
  end

  # --- Account ---

  # GET /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/balance
  def balance
    render_result account_service.get_balance
  end

  # GET /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:id/business_accounts
  def list_business_accounts
    render_result account_service.list_business_accounts(page: params[:page] || 1, limit: params[:limit] || 20)
  end

  private

  def check_authorization
    authorize(Current.account, :update?)
  end

  def set_channel
    @inbox = Current.account.inboxes.find(params[:id])
    @channel = @inbox.channel
  end

  def ensure_ycloud_provider
    return if @channel.is_a?(Channel::Whatsapp) && @channel.provider == 'ycloud'

    render json: { error: 'This inbox is not a YCloud WhatsApp channel' }, status: :unprocessable_entity
  end

  def provider_service
    @provider_service ||= Whatsapp::Providers::WhatsappYcloudService.new(whatsapp_channel: @channel)
  end

  def template_service
    @template_service ||= Whatsapp::Ycloud::TemplateService.new(whatsapp_channel: @channel)
  end

  def flow_service
    @flow_service ||= Whatsapp::Ycloud::FlowService.new(whatsapp_channel: @channel)
  end

  def call_service
    @call_service ||= Whatsapp::Ycloud::CallService.new(whatsapp_channel: @channel)
  end

  def profile_service
    @profile_service ||= Whatsapp::Ycloud::ProfileService.new(whatsapp_channel: @channel)
  end

  def contact_service
    @contact_service ||= Whatsapp::Ycloud::ContactService.new(whatsapp_channel: @channel)
  end

  def event_service
    @event_service ||= Whatsapp::Ycloud::EventService.new(whatsapp_channel: @channel)
  end

  def multi_channel_service
    @multi_channel_service ||= Whatsapp::Ycloud::MultiChannelService.new(whatsapp_channel: @channel)
  end

  def unsubscriber_service
    @unsubscriber_service ||= Whatsapp::Ycloud::UnsubscriberService.new(whatsapp_channel: @channel)
  end

  def webhook_service
    @webhook_service ||= Whatsapp::Ycloud::WebhookService.new(whatsapp_channel: @channel)
  end

  def account_service
    @account_service ||= Whatsapp::Ycloud::AccountService.new(whatsapp_channel: @channel)
  end

  def render_result(response)
    if response.is_a?(HTTParty::Response)
      render json: response.parsed_response, status: response.code
    else
      render json: response || {}
    end
  end

  # --- Strong parameters ---

  def template_params
    params.permit(:name, :language, :category, :wabaId, components: {})
  end

  def flow_params
    params.permit(:name, :wabaId, :flowJson, :publish, :endpointUri, categories: [])
  end

  def profile_params
    params.permit(:about, :address, :description, :email, :vertical, :profilePictureUrl, websites: [])
  end

  def commerce_params
    params.permit(:isCatalogVisible, :isCartEnabled)
  end

  def call_params
    params.permit(:to, :callId, :sdpOffer, :sdpAnswer)
  end

  def ycloud_contact_params
    params.permit(:nickname, :countryCode, :phoneNumber, :email, tags: [], customAttributes: {})
  end

  def event_definition_params
    params.permit(:name, :label, :description)
  end

  def custom_event_params
    params.permit(:eventName, :occurredAt, contact: {}, properties: {})
  end

  def sms_params
    params.permit(:to, :text, :from)
  end

  def email_params
    params.permit(:from, :to, :subject, :contentType, :content)
  end

  def voice_params
    params.permit(:to, :verificationCode, :language)
  end

  def verification_params
    params.permit(:channel, :to, :codeLength, :locale, :senderId)
  end

  def verification_check_params
    params.permit(:verificationId, :code)
  end

  def unsubscriber_params
    params.permit(:customer, :channel)
  end
end
