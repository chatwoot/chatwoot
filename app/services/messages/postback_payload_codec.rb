# Encodes the originating outgoing message id into a Facebook/Instagram postback
# payload so the reply webhook can look up its source message directly instead of
# guessing from recent outgoing messages with a matching (form-local, reused) payload.
module Messages::PostbackPayloadCodec
  DELIMITER = '::cw_msg::'.freeze
  MESSAGE_ID_PATTERN = /\A\d+\z/

  module_function

  def encode(message_id, payload)
    "#{message_id}#{DELIMITER}#{payload}"
  end

  # Returns [message_id, original_payload] or nil if not one of our encoded payloads
  # (e.g. an Instagram Ads Quick Reply postback, or one sent before this was introduced).
  def decode(encoded_payload)
    return nil unless encoded_payload.is_a?(String) && encoded_payload.include?(DELIMITER)

    message_id, original_payload = encoded_payload.split(DELIMITER, 2)
    return nil unless message_id.match?(MESSAGE_ID_PATTERN)

    [message_id.to_i, original_payload]
  end
end
