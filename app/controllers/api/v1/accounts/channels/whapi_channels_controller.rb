# frozen_string_literal: true

class Api::V1::Accounts::Channels::WhapiChannelsController < Api::V1::Accounts::BaseController
  before_action :authorize_request, only: [:create]
  before_action :fetch_inbox, only: [:get_qr, :qr_status, :complete_setup]

  def create
    Rails.logger.info "[WHATSAPP_LIGHT] Controller: Starting inbox creation"
    Rails.logger.info "[WHATSAPP_LIGHT] Controller: Phone: #{permitted_params[:phone_number]}, Name: #{permitted_params[:name]}"

    result = Whatsapp::WhapiChannelCreationService.new(
      account: Current.account,
      phone_number: permitted_params[:phone_number],
      inbox_name: permitted_params[:name]
    ).perform

    @inbox = result[:inbox]
    @channel = result[:channel]

    Rails.logger.info "[WHATSAPP_LIGHT] Controller: Channel created successfully"
    Rails.logger.info "[WHATSAPP_LIGHT] Controller: Saved channel_id: #{@channel.provider_config['channel_id']}"
    Rails.logger.info "[WHATSAPP_LIGHT] Controller: Saved token: #{@channel.provider_config['token']}"
    Rails.logger.info "[WHATSAPP_LIGHT] Controller: Redirecting to agent assignment, QR will be obtained later"

    render json: {
      inbox: inbox_payload
    }, status: :created
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP_LIGHT] Controller: Error - #{e.message}"
    Rails.logger.error "[WHATSAPP_LIGHT] Controller: Backtrace - #{e.backtrace.first(5).join("\n")}"
    render_error(e.message)
  end

  def get_qr
    Rails.logger.info "[WHATSAPP_LIGHT] Controller: Fetching QR code for inbox #{@inbox.id}"

    qr_data = Whatsapp::WhapiQrLoginService.new(channel: @inbox.channel).perform

    Rails.logger.info "[WHATSAPP_LIGHT] Controller: QR code obtained successfully"

    render json: {
      qr: qr_data
    }
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP_LIGHT] Controller: QR fetch error - #{e.message}"

    # Return waiting status if service is temporarily unavailable
    if e.message.include?('503') || e.message.include?('Temporary Unavailable')
      render json: {
        status: 'waiting',
        message: 'Channel is being provisioned, please wait...'
      }
    else
      render_error(e.message)
    end
  end

  def qr_status
    health_service = Whatsapp::WhapiHealthService.new(channel: @inbox.channel)
    health_data = health_service.perform
    authenticated = health_service.authenticated?

    # If authenticated, setup webhooks
    if authenticated
      setup_webhooks_async
    end

    render json: {
      authenticated: authenticated,
      status_code: health_data[:status_code],
      status_text: health_data[:status_text]
    }
  rescue StandardError => e
    render_error(e.message)
  end

  def complete_setup
    # This endpoint is called after successful authentication
    # to finalize the setup
    begin
      Whatsapp::WhapiWebhookSetupService.new(
        channel: @inbox.channel,
        inbox_id: @inbox.id
      ).perform

      render json: {
        success: true,
        inbox: inbox_payload
      }
    rescue StandardError => e
      render_error(e.message)
    end
  end

  private

  def authorize_request
    authorize ::Inbox
  end

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:id])
    authorize @inbox, :show?
  end

  def setup_webhooks_async
    # Setup webhooks in background to avoid blocking the polling request
    SetupWhapiWebhooksJob.perform_later(@inbox.id)
  end

  def inbox_payload
    {
      id: @inbox.id,
      name: @inbox.name,
      channel_type: @inbox.channel_type,
      phone_number: @inbox.channel.phone_number
    }
  end

  def permitted_params
    params.require(:whapi_channel).permit(:name, :phone_number)
  end

  def render_error(message)
    render json: { error: message }, status: :unprocessable_entity
  end

  def fetch_qr_with_retry(channel, max_retries: 5, delay: 3)
    retries = 0

    loop do
      begin
        Rails.logger.info "[WHATSAPP_LIGHT] Controller: QR fetch attempt #{retries + 1}/#{max_retries}"
        return Whatsapp::WhapiQrLoginService.new(channel: channel).perform
      rescue StandardError => e
        retries += 1

        if retries >= max_retries
          Rails.logger.error "[WHATSAPP_LIGHT] Controller: Max retries reached, giving up"
          raise e
        end

        Rails.logger.warn "[WHATSAPP_LIGHT] Controller: QR fetch failed (#{e.message}), retrying in #{delay} seconds..."
        sleep(delay)
      end
    end
  end
end
