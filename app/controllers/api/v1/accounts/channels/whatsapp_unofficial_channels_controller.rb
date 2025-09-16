class Api::V1::Accounts::Channels::WhatsappUnofficialChannelsController < Api::V1::Accounts::BaseController
  include ChannelLimitationConcern
  
  def create
    account = Account.find(params[:account_id])
    inbox_name = params[:inbox_name]
    phone_number = params[:phone_number]

    result = ::WhatsappUnofficial::CreateWhatsappUnofficialInboxService.new(
      account_id: account.id,
      phone_number: phone_number,
      inbox_name: inbox_name
    ).perform

    inbox = result[:inbox]
    webhook_url = result[:webhook_url]

    render json: { 
      webhook_url: webhook_url, 
      inbox_id: inbox.id, 
      message: 'WhatsApp unofficial channel created. Device setup is in progress...',
      status: 'created'
    }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotUnique => e
    render json: { error: 'Phone number already exists' }, status: :bad_request
  end

  def status
    channel = Current.account.channel_whatsapp_unofficials.find(params[:id])
    
    render json: {
      phone_number: channel.phone_number,
      webhook_url: channel.webhook_url,
      token_present: channel.token.present?,
      waha_configured: channel.waha_configured?,
      session_status: channel.session_status
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Channel not found' }, status: :not_found
  end

  def qr_code
    channel = Current.account.channel_whatsapp_unofficials.find(params[:id])
    
    qr_data = channel.qr_code
    if qr_data
      render json: { qr_code: qr_data }
    else
      render json: { error: 'QR code not available. Make sure device is set up and session is initialized.' }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Channel not found' }, status: :not_found
  end
end
