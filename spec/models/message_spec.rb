# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join 'spec/models/concerns/liquidable_shared.rb'

RSpec.describe Message do
  context 'with validations' do
    it { is_expected.to validate_presence_of(:inbox_id) }
    it { is_expected.to validate_presence_of(:conversation_id) }
    it { is_expected.to validate_presence_of(:account_id) }
  end

  describe 'length validations' do
    let!(:message) { create(:message) }

    context 'when it validates name length' do
      it 'valid when within limit' do
        message.content = 'a' * 120_000
        expect(message.valid?).to be true
      end

      it 'invalid when crossed the limit' do
        message.content = 'a' * 150_001
        message.processed_message_content = 'a' * 150_001
        message.valid?

        expect(message.errors[:processed_message_content]).to include('is too long (maximum is 150000 characters)')
        expect(message.errors[:content]).to include('is too long (maximum is 150000 characters)')
      end

      it 'adds error in case of message flooding' do
        with_modified_env 'CONVERSATION_MESSAGE_PER_MINUTE_LIMIT': '2' do
          conversation = message.conversation
          create(:message, conversation: conversation)
          conv_new_message = build(:message, conversation: message.conversation)

          expect(conv_new_message.valid?).to be false
          expect(conv_new_message.errors[:base]).to eq(['Too many messages'])
        end
      end
    end
  end

  describe 'concerns' do
    it_behaves_like 'liqudable'
  end

  describe 'message_filter_helpers' do
    context 'when webhook_sendable?' do
      [
        { type: :incoming, expected: true },
        { type: :outgoing, expected: true },
        { type: :template, expected: true },
        { type: :activity, expected: false }
      ].each do |scenario|
        it "returns #{scenario[:expected]} for #{scenario[:type]} message" do
          message = create(:message, message_type: scenario[:type])
          expect(message.webhook_sendable?).to eq(scenario[:expected])
        end
      end
    end
  end

  describe '#push_event_data' do
    subject(:push_event_data) { message.push_event_data }

    let(:message) { create(:message, echo_id: 'random-echo_id') }

    let(:expected_data) do
      {

        account_id: message.account_id,
        additional_attributes: message.additional_attributes,
        content_attributes: message.content_attributes,
        content_type: message.content_type,
        content: message.content,
        conversation_id: message.conversation.display_id,
        created_at: message.created_at.to_i,
        external_source_ids: message.external_source_ids,
        id: message.id,
        inbox_id: message.inbox_id,
        message_type: message.message_type_before_type_cast,
        private: message.private,
        processed_message_content: message.processed_message_content,
        sender_id: message.sender_id,
        sender_type: message.sender_type,
        source_id: message.source_id,
        status: message.status,
        updated_at: message.updated_at,
        conversation: {
          assignee_id: message.conversation.assignee_id,
          contact_inbox: {
            source_id: message.conversation.contact_inbox.source_id
          },
          last_activity_at: message.conversation.last_activity_at.to_i,
          unread_count: message.conversation.unread_incoming_messages.count
        },
        sentiment: {},
        sender: message.sender.push_event_data,
        echo_id: 'random-echo_id'
      }
    end

    it 'returns push event payload' do
      expect(push_event_data).to eq(expected_data)
    end
  end

  describe 'message create event' do
    let!(:conversation) { create(:conversation) }

    before do
      conversation.reload
    end

    it 'updates the conversation first reply created at if it is the first outgoing message' do
      expect(conversation.first_reply_created_at).to be_nil
      expect(conversation.waiting_since).to eq conversation.created_at

      outgoing_message = create(:message, message_type: :outgoing, conversation: conversation)

      expect(conversation.first_reply_created_at).to eq outgoing_message.created_at
      expect(conversation.waiting_since).to be_nil
    end

    it 'does not update the conversation first reply created at if the message is incoming' do
      expect(conversation.first_reply_created_at).to be_nil
      expect(conversation.waiting_since).to eq conversation.created_at

      create(:message, message_type: :incoming, conversation: conversation)

      expect(conversation.first_reply_created_at).to be_nil
      expect(conversation.waiting_since).to eq conversation.created_at
    end

    it 'does not update the conversation first reply created at if the message is template' do
      expect(conversation.first_reply_created_at).to be_nil
      expect(conversation.waiting_since).to eq conversation.created_at

      create(:message, message_type: :template, conversation: conversation)

      expect(conversation.first_reply_created_at).to be_nil
      expect(conversation.waiting_since).to eq conversation.created_at
    end

    it 'does not update the conversation first reply created at if the message is activity' do
      expect(conversation.first_reply_created_at).to be_nil
      expect(conversation.waiting_since).to eq conversation.created_at

      create(:message, message_type: :activity, conversation: conversation)

      expect(conversation.first_reply_created_at).to be_nil
      expect(conversation.waiting_since).to eq conversation.created_at
    end

    it 'does not update the conversation first reply created at if the message is a private message' do
      expect(conversation.first_reply_created_at).to be_nil
      expect(conversation.waiting_since).to eq conversation.created_at

      create(:message, message_type: :outgoing, conversation: conversation, private: true)

      expect(conversation.first_reply_created_at).to be_nil
      expect(conversation.waiting_since).to eq conversation.created_at

      next_message = create(:message, message_type: :outgoing, conversation: conversation)
      expect(conversation.first_reply_created_at).to eq next_message.created_at
      expect(conversation.waiting_since).to be_nil
    end

    it 'does not update first reply if the message is sent as campaign' do
      expect(conversation.first_reply_created_at).to be_nil
      expect(conversation.waiting_since).to eq conversation.created_at

      create(:message, message_type: :outgoing, conversation: conversation, additional_attributes: { campaign_id: 1 })

      expect(conversation.first_reply_created_at).to be_nil
      expect(conversation.waiting_since).to eq conversation.created_at
    end

    it 'does not update first reply if the message is sent by automation' do
      expect(conversation.first_reply_created_at).to be_nil
      expect(conversation.waiting_since).to eq conversation.created_at

      create(:message, message_type: :outgoing, conversation: conversation, content_attributes: { automation_rule_id: 1 })

      expect(conversation.first_reply_created_at).to be_nil
      expect(conversation.waiting_since).to eq conversation.created_at
    end
  end

  describe '#reopen_conversation' do
    let(:conversation) { create(:conversation) }
    let(:message) { build(:message, message_type: :incoming, conversation: conversation) }

    it 'reopens resolved conversation when the message is from a contact' do
      conversation.resolved!
      message.save!
      expect(message.conversation.open?).to be true
    end

    it 'reopens snoozed conversation when the message is from a contact' do
      conversation.snoozed!
      message.save!
      expect(message.conversation.open?).to be true
    end

    it 'will not reopen if the conversation is muted' do
      conversation.resolved!
      conversation.mute!
      message.save!
      expect(message.conversation.open?).to be false
    end

    it 'will mark the conversation as pending if the agent bot is active' do
      agent_bot = create(:agent_bot)
      inbox = conversation.inbox
      inbox.agent_bot = agent_bot
      inbox.save!
      conversation.resolved!
      message.save!
      expect(conversation.open?).to be false
      expect(conversation.pending?).to be true
    end
  end

  describe '#waiting since' do
    let(:conversation) { create(:conversation) }
    let(:agent) { create(:user, account: conversation.account) }
    let(:message) { build(:message, conversation: conversation) }

    it 'resets the waiting_since if an agent sent a reply' do
      message.message_type = :outgoing
      message.sender = agent
      message.save!

      expect(conversation.waiting_since).to be_nil
    end

    it 'sets the waiting_since if there is an incoming message' do
      conversation.update(waiting_since: nil)
      message.message_type = :incoming
      message.save!

      expect(conversation.waiting_since).not_to be_nil
    end

    it 'does not overwrite the previous value if there are newer messages' do
      old_waiting_since = conversation.waiting_since
      message.message_type = :incoming
      message.save!
      conversation.reload

      expect(conversation.waiting_since).to eq old_waiting_since
    end
  end

  context 'with webhook_data' do
    it 'contains the message attachment when attachment is present' do
      message = create(:message)
      attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
      attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      attachment.save!
      expect(message.webhook_data.key?(:attachments)).to be true
    end

    it 'does not contain the message attachment when attachment is not present' do
      message = create(:message)
      expect(message.webhook_data.key?(:attachments)).to be false
    end
  end

  context 'when message is created' do
    let(:message) { build(:message, account: create(:account)) }

    it 'updates conversation last_activity_at when created' do
      message.save!
      expect(message.created_at).to eq message.conversation.last_activity_at
    end

    it 'updates contact last_activity_at when created' do
      expect { message.save! }.to(change { message.sender.last_activity_at })
    end

    it 'triggers ::MessageTemplates::HookExecutionService' do
      hook_execution_service = double
      allow(MessageTemplates::HookExecutionService).to receive(:new).and_return(hook_execution_service)
      allow(hook_execution_service).to receive(:perform).and_return(true)

      message.save!

      expect(MessageTemplates::HookExecutionService).to have_received(:new).with(message: message)
      expect(hook_execution_service).to have_received(:perform)
    end

    context 'with conversation continuity' do
      it 'calls notify email method on after save for outgoing messages in website channel' do
        allow(ConversationReplyEmailWorker).to receive(:perform_in).and_return(true)
        message.message_type = 'outgoing'
        message.save!
        expect(ConversationReplyEmailWorker).to have_received(:perform_in)
      end

      it 'does not call notify email for website channel if continuity is disabled' do
        message.inbox = create(:inbox, account: message.account,
                                       channel: build(:channel_widget, account: message.account, continuity_via_email: false))
        allow(ConversationReplyEmailWorker).to receive(:perform_in).and_return(true)
        message.message_type = 'outgoing'
        message.save!
        expect(ConversationReplyEmailWorker).not_to have_received(:perform_in)
      end

      it 'wont call notify email method for private notes' do
        message.private = true
        allow(ConversationReplyEmailWorker).to receive(:perform_in).and_return(true)
        message.save!
        expect(ConversationReplyEmailWorker).not_to have_received(:perform_in)
      end

      it 'calls EmailReply worker if the channel is email' do
        message.inbox = create(:inbox, account: message.account, channel: build(:channel_email, account: message.account))
        allow(EmailReplyWorker).to receive(:perform_in).and_return(true)
        message.message_type = 'outgoing'
        message.content_attributes = { email: { text_content: { quoted: 'quoted text' } } }
        message.save!
        expect(EmailReplyWorker).to have_received(:perform_in).with(1.second, message.id)
      end

      it 'wont call notify email method unless its website or email channel' do
        message.inbox = create(:inbox, account: message.account, channel: build(:channel_api, account: message.account))
        allow(ConversationReplyEmailWorker).to receive(:perform_in).and_return(true)
        message.save!
        expect(ConversationReplyEmailWorker).not_to have_received(:perform_in)
      end
    end
  end

  context 'when content_type is blank' do
    let(:message) { build(:message, content_type: nil, account: create(:account)) }

    it 'sets content_type as text' do
      message.save!
      expect(message.content_type).to eq 'text'
    end
  end

  context 'when processed_message_content is blank' do
    let(:message) { build(:message, content_type: :text, account: create(:account), content: 'Processed message content') }

    it 'sets content_type as text' do
      message.save!
      expect(message.processed_message_content).to eq message.content
    end
  end

  context 'when attachments size maximum' do
    let(:message) { build(:message, content_type: nil, account: create(:account)) }

    it 'add errors to message for attachment size is more than allowed limit' do
      16.times.each do
        attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      end

      expect(message.errors.messages).to eq({ attachments: ['exceeded maximum allowed'] })
    end
  end

  context 'when email notifiable message' do
    let(:message) { build(:message, content_type: nil, account: create(:account)) }

    it 'return false if private message' do
      message.private = true
      message.message_type = 'outgoing'
      expect(message.email_notifiable_message?).to be false
    end

    it 'return false if incoming message' do
      message.private = false
      message.message_type = 'incoming'
      expect(message.email_notifiable_message?).to be false
    end

    it 'return false if activity message' do
      message.private = false
      message.message_type = 'activity'
      expect(message.email_notifiable_message?).to be false
    end

    it 'return false if message type is template and content type is not input_csat or text' do
      message.private = false
      message.message_type = 'template'
      message.content_type = 'incoming_email'
      expect(message.email_notifiable_message?).to be false
    end

    it 'return true if not private and not incoming and message content type is input_csat or text' do
      message.private = false
      message.message_type = 'template'
      message.content_type = 'text'
      expect(message.email_notifiable_message?).to be true
    end
  end

  context 'when facebook channel with unavailable story link' do
    let(:instagram_message) { create(:message, :instagram_story_mention) }

    before do
      # stubbing the request to facebook api during the message creation
      stub_request(:get, %r{https://graph.facebook.com/.*}).to_return(status: 200, body: {
        story: { mention: { link: 'http://graph.facebook.com/test-story-mention', id: '17920786367196703' } },
        from: { username: 'Sender-id-1', id: 'Sender-id-1' },
        id: 'instagram-message-id-1234'
      }.to_json, headers: {})
    end

    it 'keeps the attachment for deleted stories' do
      expect(instagram_message.attachments.count).to eq 1
      stub_request(:get, %r{https://graph.facebook.com/.*}).to_return(status: 404)
      instagram_message.push_event_data
      expect(instagram_message.reload.attachments.count).to eq 1
    end

    it 'keeps the attachment for expired stories' do
      expect(instagram_message.attachments.count).to eq 1
      # for expired stories, the link will be empty
      stub_request(:get, %r{https://graph.facebook.com/.*}).to_return(status: 200, body: {
        story: { mention: { link: '', id: '17920786367196703' } }
      }.to_json, headers: {})
      instagram_message.push_event_data
      expect(instagram_message.reload.attachments.count).to eq 1
    end
  end

  describe '#ensure_in_reply_to' do
    let(:conversation) { create(:conversation) }
    let(:message) { create(:message, conversation: conversation, source_id: 12_345) }

    context 'when in_reply_to is present' do
      let(:content_attributes) { { in_reply_to: message.id } }
      let(:new_message) { build(:message, conversation: conversation, content_attributes: content_attributes) }

      it 'sets in_reply_to_external_id based on the source_id of the referenced message' do
        new_message.send(:ensure_in_reply_to)
        expect(new_message.content_attributes[:in_reply_to_external_id]).to eq(message.source_id)
      end
    end

    context 'when in_reply_to is not present' do
      let(:content_attributes) { { in_reply_to_external_id: message.source_id } }
      let(:new_message) { build(:message, conversation: conversation, content_attributes: content_attributes) }

      it 'sets in_reply_to based on the source_id of the referenced message' do
        new_message.send(:ensure_in_reply_to)
        expect(new_message.content_attributes[:in_reply_to]).to eq(message.id)
      end
    end

    context 'when the referenced message is not found' do
      let(:content_attributes) { { in_reply_to: message.id + 1 } }
      let(:new_message) { build(:message, conversation: conversation, content_attributes: content_attributes) }

      it 'does not set in_reply_to_external_id' do
        new_message.send(:ensure_in_reply_to)
        expect(new_message.content_attributes[:in_reply_to_external_id]).to be_nil
      end
    end

    context 'when the source message is not found' do
      let(:content_attributes) { { in_reply_to_external_id: 'source-id-that-does-not-exist' } }
      let(:new_message) { build(:message, conversation: conversation, content_attributes: content_attributes) }

      it 'does not set in_reply_to' do
        new_message.send(:ensure_in_reply_to)
        expect(new_message.content_attributes[:in_reply_to]).to be_nil
      end
    end
  end

  describe '#content' do
    let(:conversation) { create(:conversation) }
    let(:message) { create(:message, conversation: conversation, content_type: 'input_csat', content: 'Original content') }

    it 'returns original content for web widget inbox' do
      allow(message.inbox).to receive(:web_widget?).and_return(true)
      expect(message.content).to eq('Original content')
    end

    context 'when inbox is not a web widget' do
      before do
        allow(message.inbox).to receive(:web_widget?).and_return(false)
        allow(ENV).to receive(:fetch).with('FRONTEND_URL', nil).and_return('https://app.chatwoot.com')
      end

      it 'returns custom message with survey link when csat message is configured' do
        allow(message.inbox).to receive(:csat_config).and_return({ 'message' => 'Custom survey message:' })
        expected_content = "Custom survey message: https://app.chatwoot.com/survey/responses/#{conversation.uuid}"
        expect(message.content).to eq(expected_content)
      end

      it 'returns default message with survey link when no custom csat message' do
        allow(message.inbox).to receive(:csat_config).and_return(nil)
        allow(I18n).to receive(:t).with('conversations.survey.response', link: "https://app.chatwoot.com/survey/responses/#{conversation.uuid}")
                                  .and_return("Please rate your conversation: https://app.chatwoot.com/survey/responses/#{conversation.uuid}")
        expected_content = "Please rate your conversation: https://app.chatwoot.com/survey/responses/#{conversation.uuid}"
        expect(message.content).to eq(expected_content)
      end
    end
  end
end
