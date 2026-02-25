module Telegram::ParamHelpers
  # ensures that message is from a private chat and not a group chat
  def private_message?
    return true if callback_query_params?

    params.dig(:message, :chat, :type) == 'private'
  end

  def telegram_params_content_attributes
    reply_to = params.dig(:message, :reply_to_message, :message_id)
    return { 'in_reply_to_external_id' => reply_to } if reply_to

    {}
  end

  def business_message?
    telegram_params_business_connection_id.present?
  end

  # In business bot mode we will receive messages from our telegram.
  # This is our messages posted via telegram client.
  # Such messages should be outgoing (from us to client)
  def business_message_outgoing?
    business_message? && telegram_params_base_object[:chat][:id] != telegram_params_base_object[:from][:id]
  end

  def message_params?
    params[:message].present?
  end

  def callback_query_params?
    params[:callback_query].present?
  end

  def telegram_params_base_object
    if callback_query_params?
      params[:callback_query]
    else
      params[:message]
    end
  end

  def contact_params
    if business_message_outgoing?
      telegram_params_base_object[:chat]
    else
      telegram_params_base_object[:from]
    end
  end

  def telegram_params_from_id
    return telegram_params_base_object[:chat][:id] if business_message?

    telegram_params_base_object[:from][:id]
  end

  def telegram_params_first_name
    contact_params[:first_name]
  end

  def telegram_params_last_name
    contact_params[:last_name]
  end

  def telegram_params_username
    contact_params[:username]
  end

  def telegram_params_language_code
    contact_params[:language_code]
  end

  def telegram_params_chat_id
    if callback_query_params?
      params[:callback_query][:message][:chat][:id]
    else
      telegram_params_base_object[:chat][:id]
    end
  end

  def telegram_params_business_connection_id
    if callback_query_params?
      params[:callback_query][:message][:business_connection_id]
    else
      telegram_params_base_object[:business_connection_id]
    end
  end

  def telegram_params_message_content
    if callback_query_params?
      params[:callback_query][:data]
    else
      params[:message][:text].presence || params[:message][:caption]
    end
  end

  def telegram_params_message_id
    if callback_query_params?
      params[:callback_query][:id]
    else
      params[:message][:message_id]
    end
  end
end
