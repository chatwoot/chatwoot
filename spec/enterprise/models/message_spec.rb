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

  describe 'language detection' do
    let(:detection) { instance_double(Captain::Llm::LanguageDetectionService, language: 'fr') }

    before do
      conversation.account.enable_features('auto_translate', 'captain_tasks')
      conversation.account.save!
      allow(Captain::Llm::LanguageDetectionService).to receive(:new).and_return(detection)
    end

    it 'saves a message built through the conversation once while the conversation follows its language' do
      message = conversation.messages.build(account: conversation.account, inbox: conversation.inbox, message_type: :incoming,
                                            content: 'Celui-ci met quatre secondes à charger.')
      message.save!

      expect(conversation.messages.count).to eq(1)
      expect(message.reload.content_attributes['source_language']).to eq('fr')
      expect(conversation.reload.language).to eq('fr')
    end

    it 'leaves an email with an html body alone' do
      create(:message, account: conversation.account, inbox: conversation.inbox, conversation: conversation, message_type: :incoming,
                       content_type: :incoming_email, content: 'Celui-ci met quatre secondes à charger.',
                       content_attributes: { email: { html_content: { full: '<p>Celui-ci met quatre secondes à charger.</p>' } } })

      expect(Captain::Llm::LanguageDetectionService).not_to have_received(:new)
      expect(conversation.reload.language).to be_nil
    end

    it 'ignores call markers and other inbound messages that are not text' do
      create(:message, account: conversation.account, inbox: conversation.inbox, conversation: conversation, message_type: :incoming,
                       content_type: :voice_call, content: 'Voice Call')

      expect(Captain::Llm::LanguageDetectionService).not_to have_received(:new)
      expect(conversation.reload.language).to be_nil
    end

    it 'does nothing when auto translate is off for the account' do
      conversation.account.disable_features('auto_translate')
      conversation.account.save!

      create(:message, account: conversation.account, inbox: conversation.inbox, conversation: conversation, message_type: :incoming,
                       content: 'Celui-ci met quatre secondes à charger.')

      expect(Captain::Llm::LanguageDetectionService).not_to have_received(:new)
      expect(conversation.reload.language).to be_nil
    end

    it 'ignores auto reply emails and outgoing messages' do
      create(:message, account: conversation.account, inbox: conversation.inbox, conversation: conversation, message_type: :incoming,
                       content_type: :incoming_email, content: 'I am out of the office until Monday and will reply when I return.',
                       content_attributes: { email: { auto_reply: true } })
      create(:message, account: conversation.account, inbox: conversation.inbox, conversation: conversation, message_type: :outgoing,
                       content: 'Celui-ci met quatre secondes à charger.')

      expect(Captain::Llm::LanguageDetectionService).not_to have_received(:new)
      expect(conversation.reload.language).to be_nil
    end
  end
end
