class Integrations::Dialogflow::ProcessorService
  pattr_initialize [:event_name!, :hook!, :event_data!]

  def perform
    message = event_data[:message]
    return if message.private?
    return unless processable_message?(message)
    return unless message.conversation.bot?

    response = get_dialogflow_response(message.conversation.contact_inbox.source_id, message_content(message))
    process_response(message, response)
  end

  private

  def message_content(message)
    return message.content_attributes['submitted_values'].first['value'] if event_name == 'message.updated'

    message.content
  end

  def processable_message?(message)
    return unless message.reportable?
    return if message.outgoing? && !processable_outgoing_message?(message)

    true
  end

  def processable_outgoing_message?(message)
    event_name == 'message.updated' && ['input_select'].include?(message.content_type)
  end

  def get_dialogflow_response(session_id, message)
    Google::Cloud::Dialogflow.configure { |config| config.credentials = hook.settings['credentials'] }
    session_client = Google::Cloud::Dialogflow.sessions
    session = session_client.session_path project: hook.settings['project_id'], session: session_id
    query_input = { text: { text: message, language_code: 'en-US' } }
    session_client.detect_intent session: session, query_input: query_input
  end

  def process_response(message, response)
    text_response = response.query_result['fulfillment_text']

    content_params = { content: text_response } if text_response.present?
    content_params ||= response.query_result['fulfillment_messages'].first['payload'].to_h

    process_action(message, content_params['action']) and return if content_params['action'].present?

    create_conversation(message, content_params)
  end

  def create_conversation(message, content_params)
    return if content_params.blank?

    conversation = message.conversation
    conversation.messages.create(content_params.merge({
                                                        message_type: :outgoing,
                                                        account_id: conversation.account_id,
                                                        inbox_id: conversation.inbox_id
                                                      }))
  end

  def process_action(message, action)
    case action
    when 'handoff'
      message.conversation.open!
    end
  end
end
