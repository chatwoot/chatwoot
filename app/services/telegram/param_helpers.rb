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

  def telegram_params_from_id
    telegram_params_base_object[:from][:id]
  end

  def telegram_params_first_name
    telegram_params_base_object[:from][:first_name]
  end

  def telegram_params_last_name
    telegram_params_base_object[:from][:last_name]
  end

  def telegram_params_username
    telegram_params_base_object[:from][:username]
  end

  def telegram_params_language_code
    telegram_params_base_object[:from][:language_code]
  end

  def telegram_params_chat_id
    if callback_query_params?
      params[:callback_query][:message][:chat][:id]
    else
      telegram_params_base_object[:chat][:id]
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
