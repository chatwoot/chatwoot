module Api::V1::Accounts::Concerns::InboxHealthManagement
  extend ActiveSupport::Concern

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

  def health
    render json: fetch_health_data
  rescue StandardError => e
    Rails.logger.error "[INBOX HEALTH] Error fetching health data: #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def register_webhook
    register_channel_webhook

    render json: { message: 'Webhook registered successfully' }, status: :ok
  rescue StandardError => e
    Rails.logger.error "[INBOX WEBHOOK] Webhook registration failed: #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def fetch_health_data
    return Whatsapp::HealthService.new(@inbox.channel).fetch_health_status if whatsapp_cloud_channel?

    Twilio::HealthService.new(channel: @inbox.channel).perform
  end

  def register_channel_webhook
    return Whatsapp::WebhookSetupService.new(@inbox.channel).register_callback if whatsapp_cloud_channel?

    Twilio::WebhookSetupService.new(channel: @inbox.channel).perform
    # No-op unless voice is enabled; keeps the number's voice webhooks in sync alongside messaging.
    @inbox.channel.try(:reprovision_voice_webhooks!)
  end

  def validate_health_supported_channel
    return if whatsapp_cloud_channel? || twilio_sms_channel?

    render json: { error: 'Health data only available for WhatsApp Cloud API and Twilio SMS channels' }, status: :bad_request
  end

  def whatsapp_cloud_channel?
    @inbox.channel.is_a?(Channel::Whatsapp) && @inbox.channel.provider == 'whatsapp_cloud'
  end

  def twilio_sms_channel?
    @inbox.channel.is_a?(Channel::TwilioSms) && @inbox.channel.sms?
  end

  def whatsapp_channel?
    @inbox.whatsapp? || (@inbox.twilio? && @inbox.channel.whatsapp?)
  end

  def trigger_template_sync
    if @inbox.whatsapp?
      Channels::Whatsapp::TemplatesSyncJob.perform_later(@inbox.channel)
    elsif @inbox.twilio? && @inbox.channel.whatsapp?
      Channels::Twilio::TemplatesSyncJob.perform_later(@inbox.channel)
    end
  end
end
