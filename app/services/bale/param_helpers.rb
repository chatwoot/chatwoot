module Bale::ParamHelpers
  def private_message?
    return true if callback_query_params?

    params.dig(:message, :chat, :type) == 'private'
  end

  def bale_params_content_attributes
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

  def bale_params_base_object
    if callback_query_params?
      params[:callback_query]
    else
      params[:message]
    end
  end

  def contact_params
    bale_params_base_object[:from]
  end

  def bale_params_from_id
    bale_params_base_object[:from][:id]
  end

  def bale_params_first_name
    contact_params[:first_name]
  end

  def bale_params_last_name
    contact_params[:last_name]
  end

  def bale_params_username
    contact_params[:username]
  end

  def bale_params_language_code
    contact_params[:language_code]
  end

  def bale_params_chat_id
    if callback_query_params?
      params[:callback_query][:message][:chat][:id]
    else
      bale_params_base_object[:chat][:id]
    end
  end

  def bale_params_message_content
    if callback_query_params?
      params[:callback_query][:data]
    else
      params[:message][:text].presence || params[:message][:caption]
    end
  end

  def bale_params_message_id
    if callback_query_params?
      params[:callback_query][:id]
    else
      params[:message][:message_id]
    end
  end
end
