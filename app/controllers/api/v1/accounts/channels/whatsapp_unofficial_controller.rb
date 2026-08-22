# Backend proxy for the unofficial (Baileys/QR) WhatsApp companion. The admin UI
# calls these to drive the QR-login flow: connect a number, poll its QR / status.
# Chatwoot authenticates to the companion with the shared companion token
# (see Whatsapp::CompanionConfig).

class Api::V1::Accounts::Channels::WhatsappUnofficialController < Api::V1::Accounts::BaseController
  before_action :set_channel, only: [:status, :qr, :logout]
  before_action :authorize_request

  # POST /api/v1/accounts/:account_id/channels/whatsapp_unofficial/connect
  # Body: { phone_number: "15550001111" } — must match an existing unofficial channel.
  def connect
    channel = Current.account.whatsapp_channels.find_by!(
      phone_number: connect_params[:phone_number],
      provider: 'whatsapp_unofficial'
    )
    @channel = channel

    result = companion_request(
      :post,
      '/connect',
      { identifier: channel.phone_number, account_id: Current.account.id }
    )

    render json: result unless performed?
  rescue ActiveRecord::RecordNotFound
    render_not_found_error('Unofficial WhatsApp channel not found') and return
  end

  # GET /api/v1/accounts/:account_id/channels/whatsapp_unofficial/find?phone_number=...
  # Returns the existing unofficial channel for a phone number, if owned by this
  # account. Lets the add-inbox flow resume an aborted scan (whose channel row
  # already exists) instead of failing on phone_number uniqueness.
  def find
    channel = Current.account.whatsapp_channels.find_by(
      phone_number: find_params[:phone_number],
      provider: 'whatsapp_unofficial'
    )

    return render_not_found_error('Unofficial WhatsApp channel not found') if channel.blank?

    render json: { channel_id: channel.id, inbox_id: channel.inbox&.id }
  end

  # GET /api/v1/accounts/:account_id/channels/whatsapp_unofficial/:channel_id/status
  def status
    result = companion_request(:get, "/status/#{URI.encode_www_form_component(@channel.phone_number)}")
    render json: result unless performed?
  end

  # GET /api/v1/accounts/:account_id/channels/whatsapp_unofficial/:channel_id/qr
  def qr
    result = companion_request(:get, "/qr/#{URI.encode_www_form_component(@channel.phone_number)}")
    render json: result unless performed?
  end

  # POST /api/v1/accounts/:account_id/channels/whatsapp_unofficial/:channel_id/logout
  # Clears the persisted session on the companion so the next connect produces a
  # fresh QR. This is how an admin recovers a stale/ghost session that still
  # reports connected but no longer delivers messages.
  def logout
    result = companion_request(:post, "/logout/#{URI.encode_www_form_component(@channel.phone_number)}")
    render json: result unless performed?
  end

  private

  def authorize_request
    # Driving the QR-login flow mutates the channel, so require the same
    # administrator-level access as editing an inbox.
    authorize ::Inbox, :update?
  end

  def set_channel
    @channel = Current.account.whatsapp_channels.find(params[:id])
  end

  def connect_params
    params.require(:whatsapp_unofficial).permit(:phone_number)
  end

  def find_params
    params.permit(:phone_number)
  end

  def companion_request(method, path, body = nil)
    url = "#{Whatsapp::CompanionConfig.companion_url}#{path}"
    headers = { 'x-companion-token' => Whatsapp::CompanionConfig.companion_token, 'Content-Type' => 'application/json' }
    begin
      response = if method == :post
                   HTTParty.post(url, headers: headers, body: body&.to_json, timeout: 10)
                 else
                   HTTParty.get(url, headers: headers, timeout: 10)
                 end
    rescue StandardError => e
      Rails.logger.error("Whatsapp companion unreachable (#{method.upcase} #{path}): #{e.class} #{e.message}")
      render json: { error: 'Companion unreachable', details: e.message }, status: :bad_gateway and return
    end

    return response.parsed_response if response.success?

    Rails.logger.error("Whatsapp companion error (#{method.upcase} #{path}): #{response.code} #{response.body&.truncate(500)}")
    render json: { error: "Companion error: #{response.code}", details: response.parsed_response }, status: :bad_gateway and return
  end
end
