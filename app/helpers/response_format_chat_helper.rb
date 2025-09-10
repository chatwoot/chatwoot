module ResponseFormatChatHelper
  include JsonHelper

  def parsed_response(response)
    raw_message = response&.dig('response')
    message = normalize_utf8(raw_message)
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

  def normalize_utf8(string)
    string.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
  end
end
