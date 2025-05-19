class Api::V1::Accounts::Channels::WhatsappUnofficialChannelsController < Api::V1::Accounts::BaseController
  def create
    account = Account.find(params[:account_id])
    user = AccountUser.find_by(account_id: account.id)
    inbox_name = params[:inbox_name]
    phone_number = params[:phone_number]

    token = AccessToken.find_by(id: user.user_id).token

    result = ::WhatsappUnofficial::CreateWhatsappUnofficialInboxService.call(
      account_id: account.id,
      phone_number: phone_number,
      inbox_name: inbox_name,
      token: token
    )

    inbox = result[:inbox]
    webhook_url = result[:webhook_url]

    render json: { webhook_url: webhook_url, inbox_id: inbox.id, message: 'WhatsApp unofficial channel created' }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotUnique => e
    render json: { error: 'Phone number already exists' }, status: :bad_request
  end
end
