# app/controllers/webhooks/call_controller.rb
require 'json'
class Webhooks::CallController < ActionController::API
  include CallHelper
  def handle_call_callback
    payload = request.body.read
    parsed_body = JSON.parse(payload)

    conversation = Conversation.where({
                                        account_id: params[:account_id],
                                        inbox_id: params[:inbox_id],
                                        display_id: params[:conversation_id]
                                      }).first
    call_log_message = get_call_log_string(parsed_body)

    conversation.messages.create!(private_message_params(call_log_message, conversation))
    head :ok
  end

  def private_message_params(content, conversation)
    { account_id: conversation.account_id, inbox_id: conversation.inbox_id, message_type: :outgoing, content: content, private: true }
  end
end
