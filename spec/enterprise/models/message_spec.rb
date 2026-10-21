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

  describe 'anonymous caller replies' do
    let(:channel) { create(:channel_twilio_sms, :with_voice) }
    let(:contact_inbox) do
      create(:contact_inbox, inbox: channel.inbox, source_id: "anonymous:CA#{SecureRandom.hex(16)}")
    end
    let(:conversation) do
      create(:conversation, account: channel.account, inbox: channel.inbox, contact: contact_inbox.contact, contact_inbox: contact_inbox)
    end

    [:outgoing, :template].each do |message_type|
      it "rejects public #{message_type} messages" do
        message = build(:message, conversation: conversation, message_type: message_type)

        expect(message).not_to be_valid
        expect(message.errors[:base]).to include(I18n.t('errors.conversations.anonymous_caller_reply'))
      end
    end

    it 'allows private notes' do
      expect(build(:message, conversation: conversation, message_type: :outgoing, private: true)).to be_valid
    end

    it 'allows voice call messages' do
      expect(build(:message, conversation: conversation, message_type: :outgoing, content_type: :voice_call)).to be_valid
    end

    it 'allows incoming messages' do
      expect(build(:message, conversation: conversation, message_type: :incoming)).to be_valid
    end

    it 'allows public replies to numbered callers' do
      contact_inbox.update!(source_id: '+14157047320')

      expect(build(:message, conversation: conversation, message_type: :outgoing)).to be_valid
      expect(conversation.can_reply?).to be true
    end
  end

  describe '#mark_pending_conversation_as_open_for_human_response' do
    let(:conversation) { create(:conversation, status: :pending) }
    let(:captain_assistant) { create(:captain_assistant, account: conversation.account) }
    let(:auto_open_activity_content) { I18n.t('conversations.activity.captain.auto_opened_after_agent_reply', locale: conversation.account.locale) }

    before do
      create(:captain_inbox, inbox: conversation.inbox, captain_assistant: captain_assistant)
    end

    it 'opens the conversation and clears Captain ownership when a human sends a public outgoing message' do
      conversation.update!(ai_assignee: captain_assistant)

      create(:message, message_type: :outgoing, conversation: conversation)

      expect(conversation.reload).to have_attributes(status: 'open', ai_assignee: nil, ai_assignee_type: nil)
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

  describe 'translation flag' do
    let(:conversation) { create(:conversation, additional_attributes: { 'conversation_language' => 'fr' }) }
    let(:agent) { create(:user, account: conversation.account) }

    before do
      conversation.account.enable_features('auto_translate', 'captain_tasks')
      conversation.account.update!(auto_translate: true)
    end

    it 'marks templates and agent replies for the send job' do
      template = create(:message, account: conversation.account, inbox: conversation.inbox, conversation: conversation, message_type: :template,
                                  content: 'Hello')
      reply = create(:message, account: conversation.account, inbox: conversation.inbox, conversation: conversation, message_type: :outgoing,
                               sender: agent, content: 'Hello')

      expect([template, reply].map { |message| message.content_attributes['translation_pending'] }).to eq([true, true])
    end

    it 'leaves contact messages, private notes, bot replies, activity and forwarded replies alone' do
      incoming = create(:message, account: conversation.account, inbox: conversation.inbox, conversation: conversation, message_type: :incoming,
                                  content: 'Bonjour')
      forwarded = create(:message, account: conversation.account, inbox: conversation.inbox, conversation: conversation, message_type: :outgoing,
                                   sender: agent, content: 'Hello', content_attributes: { forwarded_message_id: incoming.id })
      note = create(:message, account: conversation.account, inbox: conversation.inbox, conversation: conversation, message_type: :outgoing,
                              sender: agent, content: 'Hello', private: true)
      bot = create(:message, account: conversation.account, inbox: conversation.inbox, conversation: conversation, message_type: :outgoing,
                             sender: create(:agent_bot, account: conversation.account), content: 'Hello')
      activity = create(:message, account: conversation.account, inbox: conversation.inbox, conversation: conversation, message_type: :activity,
                                  content: 'Resolved')

      expect([incoming, note, bot, activity, forwarded].map { |message| message.content_attributes.key?('translation_pending') }).to eq([false] * 5)
    end

    it 'does nothing while auto translate is off for the account' do
      conversation.account.update!(auto_translate: false)
      reply = create(:message, account: conversation.account, inbox: conversation.inbox, conversation: conversation, message_type: :outgoing,
                               sender: agent, content: 'Hello')

      expect(reply.content_attributes).not_to have_key('translation_pending')
    end
  end
end
