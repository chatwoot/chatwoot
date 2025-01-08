class Captain::Conversation::ResponseBuilderJob < ApplicationJob
  pattr_initialize [:conversation!, assistant!]

  def perform(conversation, assistant)
    ActiveRecord::Base.transaction do
      @response = Captain::Llm::AssistantChatService.new(assistant: assistant).generate_response(
        conversation.messages.last,
        previous_messages: get_previous_messages(conver)
      )
      process_response
    end
  rescue StandardError => e
    process_action('handoff') # something went wrong, pass to agent
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
    true
  end

  private

  delegate :contact, :account, :inbox, to: :conversation


  def get_previous_messages
    conversation.messages.where(message_type: [:outgoing, :incoming]).where(private: false).find_each do |message|
      next if message.content_type != 'text'

      role = determine_role(message)
      previous_messages << { content: message.content, role: role }
    end
  end

  def determine_role(message)
    message.message_type == 'incoming' ? 'user' : 'system'
  end

  def process_response
    if @response['response'] == 'conversation_handoff'
      process_action('handoff')
    else
      create_messages
    end
  end

  def process_action(action)
    case action
    when 'handoff'
      conversation.messages.create!('message_type': :outgoing, 'account_id': conversation.account_id, 'inbox_id': conversation.inbox_id,
                                    'content': 'Transferring to another agent for further assistance.')
      conversation.bot_handoff!
    end
  end

  def create_messages
    message_content = @response['response']
    message_content += self.class.generate_sources_section(@response['context_ids']) if @response['context_ids'].present?

    create_outgoing_message(message_content)
  end

  def create_outgoing_message(message_content)
    conversation.messages.create!(
      {
        message_type: :outgoing,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        content: message_content
      }
    )
  end
end
