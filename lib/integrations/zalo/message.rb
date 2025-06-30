class Integrations::Zalo::Message < Integrations::Zalo::Authenticated
  # Sends a message to a user via Zalo's API.
  #
  # @param user_id [String] The ID of the user to send the message to.
  # @param message [String] The text message to send.
  # @return [HTTParty::Response] The response from the Zalo API.
  #
  # Example usage:
  #   message = 'Hello!'
  #   send_message('user123', text_message)
  def send_message(user_id, text)
    return {} if text.blank?

    payload = {
      recipient: { user_id: user_id },
      message: { text: text },
    }
    client
      .body(payload)
      .post('v3.0/oa/message/cs')
  end

  # Sends an attachment to a user via Zalo's API.
  # @param user_id [String] The ID of the user to send the attachment to.
  # @param attachment [Object] The attachment object containing file type and download URL.
  # @return [HTTParty::Response] The response from the Zalo API.
  def send_attachment(user_id, attachment)
    payload = {
      recipient: { user_id: user_id },
      message: { attachment: attachment },
    }
    client
      .body(payload)
      .post('v3.0/oa/message/cs')
  end
end
