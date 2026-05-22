require 'rails_helper'

RSpec.describe Message do
  let!(:conversation) { create(:conversation) }

  it 'updates first reply if the message is human and even if there are messages from captain' do
    captain_assistant = create(:captain_assistant, account: conversation.account)
    expect(conversation.first_reply_created_at).to be_nil

    ## There is a difference on how the time is stored in the database and how it is retrieved
    # This is because of the precision of the time stored in the database
    # In the test, we will check whether the time is within the range
    expect(conversation.waiting_since).to be_within(0.000001.seconds).of(conversation.created_at)

    create(:message, message_type: :outgoing, conversation: conversation, sender: captain_assistant)

    # Captain::Assistant responses clear waiting_since (like AgentBot)
    expect(conversation.first_reply_created_at).to be_nil
    expect(conversation.waiting_since).to be_nil

    create(:message, message_type: :outgoing, conversation: conversation)

    expect(conversation.first_reply_created_at).not_to be_nil
    expect(conversation.waiting_since).to be_nil
  end

  describe '#captain_run_context' do
    it 'restores the final response from message content without mutating additional attributes' do
      message = create(
        :message,
        message_type: :outgoing,
        conversation: conversation,
        content: 'Visible response',
        additional_attributes: {
          'captain' => {
            'version' => 'v2',
            'run' => {
              'messages' => [
                { 'role' => 'tool', 'content' => 'FAQ result', 'tool_call_id' => 'call_1' },
                {
                  'role' => 'assistant',
                  'content' => { 'reasoning' => 'Used FAQ' },
                  'agent_name' => 'assistant'
                }
              ],
              'handoff_tool_called' => false
            }
          }
        }
      )

      run_context = message.captain_run_context

      expect(run_context['messages'].last['content']).to eq({
                                                              'reasoning' => 'Used FAQ',
                                                              'response' => 'Visible response'
                                                            })
      expect(message.additional_attributes.dig('captain', 'run', 'messages').last['content']).to eq({ 'reasoning' => 'Used FAQ' })
    end

    it 'returns nil when the message has no Captain V2 run context' do
      message = create(:message, message_type: :outgoing, conversation: conversation, additional_attributes: {})

      expect(message.captain_run_context).to be_nil
    end
  end

  describe '#mark_pending_conversation_as_open_for_human_response' do
    let(:conversation) { create(:conversation, status: :pending) }
    let(:captain_assistant) { create(:captain_assistant, account: conversation.account) }
    let(:auto_open_activity_content) { I18n.t('conversations.activity.captain.auto_opened_after_agent_reply', locale: conversation.account.locale) }

    before do
      create(:captain_inbox, inbox: conversation.inbox, captain_assistant: captain_assistant)
    end

    it 'marks the conversation open when a human sends a public outgoing message' do
      create(:message, message_type: :outgoing, conversation: conversation)

      expect(conversation.reload.open?).to be true
    end

    it 'creates an activity message when a human sends a public outgoing message' do
      expect do
        create(:message, message_type: :outgoing, conversation: conversation)
      end.to have_enqueued_job(Conversations::ActivityMessageJob).with(
        conversation,
        {
          account_id: conversation.account_id,
          inbox_id: conversation.inbox_id,
          message_type: :activity,
          content: auto_open_activity_content
        }
      )
    end

    it 'creates an activity message for external echo replies' do
      message = build(
        :message,
        message_type: :outgoing,
        conversation: conversation,
        content_attributes: { external_echo: true }
      )
      message.sender = nil

      expect do
        message.save!
      end.to have_enqueued_job(Conversations::ActivityMessageJob).with(
        conversation,
        {
          account_id: conversation.account_id,
          inbox_id: conversation.inbox_id,
          message_type: :activity,
          content: auto_open_activity_content
        }
      )
    end

    it 'does not mark the conversation open for private outgoing messages' do
      create(:message, message_type: :outgoing, conversation: conversation, private: true)

      expect(conversation.reload.pending?).to be true
    end

    it 'does not mark the conversation open for bot outgoing messages' do
      agent_bot = create(:agent_bot, account: conversation.account)
      create(:message, message_type: :outgoing, conversation: conversation, sender: agent_bot)

      expect(conversation.reload.pending?).to be true
    end
  end
end
