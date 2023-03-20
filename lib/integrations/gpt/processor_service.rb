class Integrations::Gpt::ProcessorService < Integrations::BotProcessorService
  pattr_initialize [:event_name!, :event_data!, :agent_bot!]

  private

  def get_response(_source_id, _content)
    previous_messages = []
    conversation.messages.where(message_type: [:outgoing, :incoming]).where(private: false).each do |message|
      role = message.message_type == 'incoming' ? 'user' : 'system'
      previous_messages << { content: message.content, role: role }
    end
    ChatGpt.new(agent_bot.bot_config['api_key']).generate_response('', previous_messages)
  end

  def process_response(message, response)
    if response == 'conversation_handoff'
      process_action(message, 'handoff')
    else
      create_messages(response, conversation)
    end
  end

  def create_messages(response, conversation)
    conversation.messages.create!(
      {
        message_type: :outgoing,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        content: response,
        sender: agent_bot
      }
    )
  end
end
