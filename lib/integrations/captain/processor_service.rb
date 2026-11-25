class Integrations::Captain::ProcessorService < Integrations::BotProcessorService
  # The long ceiling of the sweep, and deliberately so: on the other side of this call an
  # assistant is composing an answer, so the thinking time before the first byte is the
  # whole point of the call and not a symptom. A short ceiling here would not protect a
  # worker, it would turn every slow answer into no answer at all.
  #
  # `max_retries: 0` matters more here than anywhere else: this is not idempotent in any
  # sense the caller cares about, since a repeat is a second answer written into the
  # conversation.
  CAPTAIN_REQUEST_OPTIONS = { timeout: 120, max_retries: 0 }.freeze

  pattr_initialize [:event_name!, :hook!, :event_data!]

  private

  def get_response(_session_id, message_content)
    call_captain(message_content)
  end

  def process_response(message, response)
    if response == 'conversation_handoff'
      message.conversation.bot_handoff!
    else
      create_conversation(message, { content: response })
    end
  end

  def create_conversation(message, content_params)
    return if content_params.blank?

    conversation = message.conversation
    conversation.messages.create!(
      content_params.merge(
        {
          message_type: :outgoing,
          account_id: conversation.account_id,
          inbox_id: conversation.inbox_id
        }
      )
    )
  end

  def call_captain(message_content)
    url = "#{GlobalConfigService.load('CAPTAIN_API_URL',
                                      '')}/accounts/#{hook.settings['account_id']}/assistants/#{hook.settings['assistant_id']}/chat"

    headers = {
      'X-USER-EMAIL' => hook.settings['account_email'],
      'X-USER-TOKEN' => hook.settings['access_token'],
      'Content-Type' => 'application/json'
    }

    body = {
      message: message_content,
      previous_messages: previous_messages
    }

    response = HTTParty.post(url, headers: headers, body: body.to_json, **CAPTAIN_REQUEST_OPTIONS)
    response.parsed_response['message']
  end

  def previous_messages
    previous_messages = []
    conversation.messages.where(message_type: [:outgoing, :incoming]).where(private: false).offset(1).find_each do |message|
      next if message.content_type != 'text'

      role = determine_role(message)
      previous_messages << { message: message.content, type: role }
    end
    previous_messages
  end

  def determine_role(message)
    message.message_type == 'incoming' ? 'User' : 'Bot'
  end
end
