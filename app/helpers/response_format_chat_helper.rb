module ResponseFormatChatHelper
  include JsonHelper

  def parsed_response(response, is_flowise: false)
    json_data =
      if is_flowise
        extract_json_from_code_block(response['text'])
      else
        response
      end

    message = json_data&.dig('response')
    is_handover = json_data&.dig('is_handover_human') || false

    [message, is_handover]
  end
end
