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
    let(:message) { create(:message) }

    context 'when it validates name length' do
      it 'valid when within limit' do
        message.content = 'a' * 120_000
        expect(message.valid?).to be true
      end

      it 'invalid when crossed the limit' do
        message.content = 'a' * 150_001
        message.valid?
        expect(message.errors[:content]).to include('is too long (maximum is 150000 characters)')
      end
    end
  end

  describe 'concerns' do
    it_behaves_like 'liqudable'
  end

  describe 'Check if message is a valid first reply' do
    it 'is valid if it is outgoing' do
      outgoing_message = create(:message, message_type: :outgoing)
      expect(outgoing_message.valid_first_reply?).to be true
    end

    it 'is invalid if it is not outgoing' do
      incoming_message = create(:message, message_type: :incoming)
      expect(incoming_message.valid_first_reply?).to be false

      activity_message = create(:message, message_type: :activity)
      expect(activity_message.valid_first_reply?).to be false

      template_message = create(:message, message_type: :template)
      expect(template_message.valid_first_reply?).to be false
    end

    it 'is invalid if it is outgoing but private' do
      conversation = create(:conversation)

      outgoing_message = create(:message, message_type: :outgoing, conversation: conversation, private: true)
      expect(outgoing_message.valid_first_reply?).to be false

      # next message should be a valid reply
      next_message = create(:message, message_type: :outgoing, conversation: conversation)
      expect(next_message.valid_first_reply?).to be true
    end

    it 'is invalid if it is not the first reply' do
      conversation = create(:conversation)
      first_message = create(:message, message_type: :outgoing, conversation: conversation)
      expect(first_message.valid_first_reply?).to be true

      second_message = create(:message, message_type: :outgoing, conversation: conversation)
      expect(second_message.valid_first_reply?).to be false
    end

    it 'is invalid if it is sent as campaign' do
      conversation = create(:conversation)
      campaign_message = create(:message, message_type: :outgoing, conversation: conversation, additional_attributes: { campaign_id: 1 })
      expect(campaign_message.valid_first_reply?).to be false

      second_message = create(:message, message_type: :outgoing, conversation: conversation)
      expect(second_message.valid_first_reply?).to be true
    end

    it 'is invalid if it is sent by automation' do
      conversation = create(:conversation)
      automation_message = create(:message, message_type: :outgoing, conversation: conversation, content_attributes: { automation_rule_id: 1 })
      expect(automation_message.valid_first_reply?).to be false
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
end
