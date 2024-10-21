require 'httparty'
require 'json'
require 'rexml/document'

class Api::V1::Accounts::Conversations::CallController < Api::V1::Accounts::Conversations::BaseController
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity
  def create
    account = Account.find_by(id: params[:account_id])

    call_config = account&.custom_attributes&.[]('call_config')

    if call_config.blank?
      render json: { success: false, error: 'Call config not found!' }, status: :bad_request
      return
    end

    payload = begin
      JSON.parse(request.body.read)
    rescue StandardError
      {}
    end

    unless payload['to'] && payload['from']
      render json: { success: false, error: 'Missing required fields: to or from' }, status: :bad_request
      return
    end

    url = "https://#{call_config['apiKey']}:#{call_config['token']}#{call_config['subDomain']}/v1/Accounts/#{call_config['sid']}/Calls/connect"

    form_data = {
      To: payload['to'],
      From: payload['from'],
      CallerId: call_config['callerId'],
      StatusCallback: payload['statusCallback'],
      'StatusCallbackEvents[0]': 'terminal',
      'StatusCallbackEvents[1]': 'answered',
      StatusCallbackContentType: 'application/json',
      Record: true
    }

    response = HTTParty.post(
      url,
      basic_auth: { username: call_config['apiKey'], password: call_config['token'] },
      body: form_data
    )

    if response.code != 200
      xml_data = REXML::Document.new(response.body)
      error_message = xml_data.elements['//Message'].text
      render json: { success: false, response: error_message }
      conversation = Conversation.where({
                                          account_id: params[:account_id],
                                          display_id: params[:conversation_id]
                                        }).first
      conversation.messages.create!(private_message_params("Error in iniating call: #{error_message}", conversation))
      return
    end
    render json: { success: true, response: response.body }
  end

  def update_call_config
    account = Account.find_by(id: params[:account_id])
    payload = begin
      JSON.parse(request.body.read)
    rescue StandardError
      {}
    end

    custom_attributes = account.custom_attributes || {}

    updated_custom_attributes = custom_attributes.merge('call_config' => payload['call_config'])

    account.update(custom_attributes: updated_custom_attributes)

    render json: { success: true, message: 'Call config updated successfully' }
  end

  def private_message_params(error, conversation)
    { account_id: conversation.account_id, inbox_id: conversation.inbox_id, message_type: :outgoing, content: '', private: true,
      additional_attributes: { type: 'error', content: error } }
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity
end
