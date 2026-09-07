module Telegram::CallbackQueryParamHelpers
  def callback_query_params?
    callback_query.present?
  end

  def processable_private_callback_query?
    valid_callback_payload? && valid_callback_participants? && private_callback_chat? && callback_participants_match?
  end

  def callback_query
    value = params[:callback_query]
    value if value.respond_to?(:key?)
  end

  def callback_query_id
    callback_query&.[](:id)
  end

  def callback_query_data
    callback_query&.[](:data)
  end

  def callback_message_chat
    callback_chat = callback_message&.[](:chat)
    callback_chat if callback_chat.respond_to?(:key?)
  end

  def callback_sender
    sender = callback_query&.[](:from)
    sender if sender.respond_to?(:key?)
  end

  def callback_chat_id
    callback_message_chat&.[](:id)
  end

  def callback_sender_id
    callback_sender&.[](:id)
  end

  def callback_business_connection_id
    callback_message&.[](:business_connection_id)
  end

  private

  def valid_callback_payload?
    callback_query_id.is_a?(String) && callback_query_id.present? &&
      callback_query_data.is_a?(String) && callback_query_data.present?
  end

  def valid_callback_participants?
    valid_telegram_id?(callback_sender_id) && valid_telegram_id?(callback_chat_id)
  end

  def valid_telegram_id?(value)
    value.is_a?(Integer) && value.positive?
  end

  def private_callback_chat?
    callback_message_chat[:type] == 'private'
  end

  def callback_participants_match?
    business_callback_query? || callback_sender_id == callback_chat_id
  end

  def business_callback_query?
    callback_business_connection_id.is_a?(String) && callback_business_connection_id.present?
  end

  def callback_message
    message = callback_query&.[](:message)
    message if message.respond_to?(:key?)
  end
end
