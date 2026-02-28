class Api::V1::Accounts::ExternalAppContextsController < Api::V1::Accounts::BaseController
  CONTEXT_EVENT = 'externalAppContext'.freeze
  SIGNATURE_ALGORITHM = 'HMAC-SHA256'.freeze

  before_action :conversation, if: :conversation_id_present?
  before_action :inbox, if: :inbox_id_present?

  def show
    data = context_data
    timestamp = Time.current.to_i
    nonce = SecureRandom.hex(16)
    payload_json = JSON.generate(data)
    signature = OpenSSL::HMAC.hexdigest(
      'SHA256',
      external_app_hmac_key,
      "#{timestamp}.#{nonce}.#{payload_json}"
    )

    render json: {
      event: CONTEXT_EVENT,
      data: data,
      timestamp: timestamp,
      nonce: nonce,
      signature: signature,
      signatureAlgorithm: SIGNATURE_ALGORITHM
    }
  end

  private

  def context_data
    {
      account: {
        id: Current.account.id,
        name: Current.account.name
      },
      currentAgent: {
        id: Current.user.id,
        name: Current.user.name,
        email: Current.user.email
      },
      conversation: conversation_data,
      route: route_data
    }
  end

  def conversation_data
    return if @conversation.blank? && @inbox.blank?

    {
      id: @conversation&.display_id,
      inboxId: @conversation&.inbox_id || @inbox.id
    }.compact
  end

  def route_data
    route_name = permitted_params[:route_name]
    route_full_path = permitted_params[:route_full_path]
    return if route_name.blank? && route_full_path.blank?

    {
      name: route_name,
      fullPath: route_full_path
    }
  end

  def conversation_id_present?
    permitted_params[:conversation_id].present?
  end

  def inbox_id_present?
    permitted_params[:inbox_id].present?
  end

  def conversation
    @conversation = Current.account.conversations.find_by!(display_id: permitted_params[:conversation_id])
    authorize @conversation, :show?
  end

  def inbox
    @inbox = Current.account.inboxes.find(permitted_params[:inbox_id])
    authorize @inbox, :show?
  end

  def external_app_hmac_key
    @external_app_hmac_key ||= GlobalConfigService.load('EXTERNAL_APP_HMAC_KEY', '').presence ||
                               Rails.application.secret_key_base.to_s
  end

  def permitted_params
    params.permit(:conversation_id, :inbox_id, :route_name, :route_full_path)
  end
end
