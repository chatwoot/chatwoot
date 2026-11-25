module Api::V1::Accounts::Concerns::InboxHealthManagement # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  # The whole of `register_webhook`, across its four Graph calls (fazer-ai/chatwoot#592). Under 15s because
  # that is where `rack-timeout` cuts a request in production unless an installation sets
  # RACK_TIMEOUT_SERVICE_TIMEOUT, and it cuts with a Thread#raise the rescue below never sees: the operator
  # gets a 500 from wherever the thread happened to be, possibly after Meta stored the subscription.
  # Answering first, with what landed, is the point. At least a full ceiling plus one more call, because the
  # subscription is the half that decides whether anything arrives, and a slow but healthy Meta must still
  # get its whole ceiling for it.
  REGISTER_WEBHOOK_DEADLINE = 12

  included do
    skip_before_action :check_authorization, only: [:health, :register_webhook]
    before_action :check_admin_authorization?, only: [:register_webhook]
    before_action :validate_health_supported_channel, only: [:health, :register_webhook]
  end

  def sync_templates
    return render status: :unprocessable_entity, json: { error: 'Template sync is only available for WhatsApp channels' } unless whatsapp_channel?

    trigger_template_sync
    render status: :ok, json: { message: 'Template sync initiated successfully' }
  rescue StandardError => e
    render status: :internal_server_error, json: { error: e.message }
  end

  def message_templates
    unless whatsapp_channel?
      return render status: :unprocessable_entity, json: { error: 'Message templates are only available for WhatsApp channels' }
    end

    templates, last_sync_attempt_at, name_key = message_template_data
    templates = templates.select { |template| template[name_key] == params[:name] } if params[:name].present?

    render json: {
      payload: templates,
      meta: { last_sync_attempt_at: last_sync_attempt_at }
    }
  end

  def health
    render json: fetch_health_data
  rescue Whatsapp::HealthService::ApiError => e
    Rails.logger.error "[INBOX HEALTH] Error fetching health data: #{e.message}"
    render json: {
      error: {
        type: e.authorization_error? ? 'authorization' : 'api',
        message: e.message,
        http_status: e.http_status,
        code: e.code,
        subcode: e.subcode
      }.compact
    }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error "[INBOX HEALTH] Error fetching health data: #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def register_webhook
    render json: register_channel_webhook, status: :ok
  rescue StandardError => e
    Rails.logger.error "[INBOX WEBHOOK] Webhook registration failed: #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def whatsapp_business_management_token
    Whatsapp::BusinessManagementTokenService.new(whatsapp_channel).update!(params.require(:business_management_token))

    head :no_content
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    render json: { error: e.message, message: e.message }, status: :unprocessable_entity
  end

  private

  def fetch_health_data
    return Twilio::HealthService.new(channel: @inbox.channel).perform unless whatsapp_cloud_channel?

    health_data = Whatsapp::HealthService.new(@inbox.channel).sync_health_status!(include_business_profile: true)
    health_data.merge(routed_by_app_callback_only: routed_by_app_callback_only?(health_data))
  end

  # The body of the 200. For WhatsApp it says which half landed and then where delivery goes; Twilio
  # has only the confirmation to give.
  def register_channel_webhook
    return register_twilio_webhook unless whatsapp_cloud_channel?

    # The per-number override is allowed to be refused without taking the channel down, so
    # "registered successfully" on its own would be the whole answer for a number Meta refused to
    # point here. The answer says which half landed, and then where delivery goes.
    deadline = Whatsapp::GraphDeadline.in(REGISTER_WEBHOOK_DEADLINE)
    applied = Whatsapp::WebhookSetupService.new(@inbox.channel, deadline: deadline).register_callback
    { message: 'Webhook registered successfully', callback_override_applied: applied }.merge(routing_after_attempt(deadline))
  end

  def register_twilio_webhook
    Twilio::WebhookSetupService.new(channel: @inbox.channel).perform
    # No-op unless voice is enabled; keeps the number's voice webhooks in sync alongside messaging.
    @inbox.channel.try(:reprovision_voice_webhooks!)
    { message: 'Webhook registered successfully' }
  end

  # `callback_override_applied` answers one write, and it answers `false` for a refusal, for a 500
  # and for a connection that closed with nothing to read alike: the rescue behind it is that wide
  # on purpose, because the same refusal arrives in all three shapes (#568). Where delivery goes
  # after the attempt is a different question, and the only authority on it is Meta. Reading it
  # back is also what separates the two cases the write cannot: a refusal leaves the routing where
  # it was, and an error that arrived after Meta stored the override leaves it changed.
  #
  # Best effort, and `routing_read_back` is why it is stated rather than implied: the write may
  # well have landed, so a read that did not come back must not turn a registration into an error,
  # and must not be answered as a routing nobody read.
  def routing_after_attempt(deadline)
    health_data = Whatsapp::HealthService.new(@inbox.channel, deadline: deadline).sync_health_status!

    {
      routing_read_back: true,
      health: health_data.merge(routed_by_app_callback_only: routed_by_app_callback_only?(health_data))
    }
  rescue StandardError => e
    Rails.logger.warn("[INBOX WEBHOOK] Registered, but reading the routing back failed: #{e.message}")
    { routing_read_back: false }
  end

  # Meta answers three levels of webhook routing and delivery follows the most specific one that
  # EXISTS, wherever it points. So this asks about existence, not about the URL: an override of
  # its own, for this number or for the WhatsApp Business Account it belongs to, means the inbox
  # owns its routing even when that override points somewhere wrong, which is a different problem
  # and already has its own warning. Only when neither exists does delivery ride on the app's own
  # callback, which belongs to the installation rather than to this inbox and can be pointed
  # elsewhere at any time. Read on every request rather than stored, so it cannot go stale against
  # Meta, and false when Meta answered no configuration at all, because not knowing is not a
  # warning.
  def routed_by_app_callback_only?(health_data)
    configuration = health_data[:webhook_configuration]
    return false if configuration.blank?

    configuration.values_at('phone_number', 'whatsapp_business_account').all?(&:blank?)
  end

  def validate_health_supported_channel
    return if whatsapp_cloud_channel? || twilio_channel?

    render json: { error: 'Health data only available for WhatsApp Cloud API and Twilio channels' }, status: :bad_request
  end

  def whatsapp_channel
    channel = @inbox.channel
    raise ActiveRecord::RecordNotFound unless channel.is_a?(Channel::Whatsapp)

    channel
  end

  def whatsapp_cloud_channel?
    @inbox.channel.is_a?(Channel::Whatsapp) && @inbox.channel.provider == 'whatsapp_cloud'
  end

  def twilio_channel?
    @inbox.channel.is_a?(Channel::TwilioSms)
  end

  def whatsapp_channel?
    @inbox.whatsapp? || (@inbox.twilio? && @inbox.channel.whatsapp?)
  end

  def message_template_data
    return [@inbox.channel.message_templates.presence || [], @inbox.channel.message_templates_last_updated, 'name'] unless @inbox.twilio_whatsapp?

    [@inbox.channel.content_templates&.dig('templates') || [], @inbox.channel.content_templates_last_updated, 'friendly_name']
  end

  def trigger_template_sync
    if @inbox.whatsapp?
      Channels::Whatsapp::TemplatesSyncJob.perform_later(@inbox.channel)
    elsif @inbox.twilio? && @inbox.channel.whatsapp?
      Channels::Twilio::TemplatesSyncJob.perform_later(@inbox.channel)
    end
  end
end
