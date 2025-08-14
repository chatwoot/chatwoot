module ResponseFormatChatHelper
  include JsonHelper

  def parsed_response(response)
    message = response&.dig('response')
    is_handover = response&.dig('is_handover_human') || false

    [message, is_handover]
  end

  def json_response(response, is_flowise: false)
    if is_flowise
      extract_json_from_code_block(response['text'])
    else
      response
    end
  end
end
