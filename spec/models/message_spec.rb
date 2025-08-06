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

    it 'uses outgoing_content for webhook content' do
      message = create(:message, content: 'Test content')
      expect(message).to receive(:outgoing_content).and_return('Outgoing test content')

      webhook_data = message.webhook_data
      expect(webhook_data[:content]).to eq('Outgoing test content')
    end

    it 'includes CSAT survey link in webhook content for input_csat messages' do
      inbox = create(:inbox, channel: create(:channel_api))
      conversation = create(:conversation, inbox: inbox)
      message = create(:message, conversation: conversation, content_type: 'input_csat', content: 'Rate your experience')

      expect(message.outgoing_content).to include('survey/responses/')
      expect(message.webhook_data[:content]).to include('survey/responses/')
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

    context 'when message is not input_csat' do
      let(:message) { create(:message, conversation: conversation, content_type: 'text', content: 'Regular message') }

      it 'returns original content' do
        expect(message.content).to eq('Regular message')
      end
    end

    context 'when message is input_csat' do
      let(:message) { create(:message, conversation: conversation, content_type: 'input_csat', content: 'Rate your experience') }

      context 'when inbox is web widget' do
        before do
          allow(message.inbox).to receive(:web_widget?).and_return(true)
        end

        it 'returns original content without survey URL' do
          expect(message.content).to eq('Rate your experience')
        end
      end

      context 'when inbox is not web widget' do
        before do
          allow(message.inbox).to receive(:web_widget?).and_return(false)
        end

        it 'returns only the stored content (clean for dashboard)' do
          expect(message.content).to eq('Rate your experience')
        end

        it 'returns only the base content without URL when survey_url stored separately' do
          message.content_attributes = { 'survey_url' => 'https://app.chatwoot.com/survey/responses/12345' }
          expect(message.content).to eq('Rate your experience')
        end
      end
    end
  end

  describe '#outgoing_content' do
    let(:conversation) { create(:conversation) }
    let(:message) { create(:message, conversation: conversation, content_type: 'text', content: 'Regular message') }

    it 'delegates to MessageContentPresenter' do
      presenter = instance_double(MessageContentPresenter)
      allow(MessageContentPresenter).to receive(:new).with(message).and_return(presenter)
      allow(presenter).to receive(:outgoing_content).and_return('Presented content')

      expect(message.outgoing_content).to eq('Presented content')
      expect(MessageContentPresenter).to have_received(:new).with(message)
      expect(presenter).to have_received(:outgoing_content)
    end
  end

  describe '#auto_reply_email?' do
    context 'when message is not an incoming email and inbox is not email' do
      let(:conversation) { create(:conversation) }
      let(:message) { create(:message, conversation: conversation, message_type: :outgoing) }

      it 'returns false' do
        expect(message.auto_reply_email?).to be false
      end
    end

    context 'when message is an incoming email' do
      let(:email_channel) { create(:channel_email) }
      let(:email_inbox) { create(:inbox, channel: email_channel) }
      let(:conversation) { create(:conversation, inbox: email_inbox) }

      it 'returns false when auto_reply is not set to true' do
        message = create(
          :message,
          conversation: conversation,
          message_type: :incoming,
          content_type: 'incoming_email',
          content_attributes: {}
        )
        expect(message.auto_reply_email?).to be false
      end

      it 'returns true when auto_reply is set to true' do
        message = create(
          :message,
          conversation: conversation,
          message_type: :incoming,
          content_type: 'incoming_email',
          content_attributes: { email: { auto_reply: true } }
        )
        expect(message.auto_reply_email?).to be true
      end
    end

    context 'when inbox is email' do
      let(:email_channel) { create(:channel_email) }
      let(:email_inbox) { create(:inbox, channel: email_channel) }
      let(:conversation) { create(:conversation, inbox: email_inbox) }

      it 'returns false when auto_reply is not set to true' do
        message = create(
          :message,
          conversation: conversation,
          message_type: :outgoing,
          content_attributes: {}
        )
        expect(message.auto_reply_email?).to be false
      end

      it 'returns true when auto_reply is set to true' do
        message = create(
          :message,
          conversation: conversation,
          message_type: :outgoing,
          content_attributes: { email: { auto_reply: true } }
        )
        expect(message.auto_reply_email?).to be true
      end
    end
  end

  describe '#should_index?' do
    let(:account) { create(:account) }
    let(:conversation) { create(:conversation, account: account) }
    let(:message) { create(:message, conversation: conversation, account: account) }

    before do
      allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true)
      account.enable_features('advanced_search')
    end

    context 'when advanced search is not allowed globally' do
      before do
        allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(false)
      end

      it 'returns false' do
        expect(message.should_index?).to be false
      end
    end

    context 'when advanced search feature is not enabled for account' do
      before do
        account.disable_features('advanced_search')
      end

      it 'returns false' do
        expect(message.should_index?).to be false
      end
    end

    context 'when message type is not incoming or outgoing' do
      before do
        message.message_type = 'activity'
      end

      it 'returns false' do
        expect(message.should_index?).to be false
      end
    end

    context 'when all conditions are met' do
      it 'returns true for incoming message' do
        message.message_type = 'incoming'
        expect(message.should_index?).to be true
      end

      it 'returns true for outgoing message' do
        message.message_type = 'outgoing'
        expect(message.should_index?).to be true
      end
    end
  end

  describe 'AI feedback functionality' do
    let(:conversation) { create(:conversation) }
    let(:message) { create(:message, conversation: conversation, content_type: 'text', content: 'Test message') }
    let(:agent) { create(:user, account: conversation.account, role: :agent) }
    let(:admin) { create(:user, account: conversation.account, role: :administrator) }

    describe 'storing AI feedback in content_attributes' do
      context 'when adding new AI feedback' do
        it 'stores feedback with all required fields' do
          feedback = {
            'rating' => 'positive',
            'feedback_text' => 'This AI response was very helpful',
            'agent_id' => agent.id,
            'created_at' => Time.current.utc.iso8601
          }

          message.content_attributes = message.content_attributes.merge('ai_feedback' => feedback)
          message.save!

          expect(message.content_attributes['ai_feedback']).to be_present
          expect(message.content_attributes['ai_feedback']['rating']).to eq('positive')
          expect(message.content_attributes['ai_feedback']['feedback_text']).to eq('This AI response was very helpful')
          expect(message.content_attributes['ai_feedback']['agent_id']).to eq(agent.id)
          expect(message.content_attributes['ai_feedback']['created_at']).to be_present
        end

        it 'stores feedback with only rating' do
          feedback = {
            'rating' => 'negative',
            'agent_id' => agent.id,
            'created_at' => Time.current.utc.iso8601
          }

          message.content_attributes = message.content_attributes.merge('ai_feedback' => feedback)
          message.save!

          expect(message.content_attributes['ai_feedback']['rating']).to eq('negative')
          expect(message.content_attributes['ai_feedback']['feedback_text']).to be_nil
          expect(message.content_attributes['ai_feedback']['agent_id']).to eq(agent.id)
        end

        it 'stores feedback with only feedback text' do
          feedback = {
            'feedback_text' => 'Could be improved with more context',
            'agent_id' => agent.id,
            'created_at' => Time.current.utc.iso8601
          }

          message.content_attributes = message.content_attributes.merge('ai_feedback' => feedback)
          message.save!

          expect(message.content_attributes['ai_feedback']['rating']).to be_nil
          expect(message.content_attributes['ai_feedback']['feedback_text']).to eq('Could be improved with more context')
          expect(message.content_attributes['ai_feedback']['agent_id']).to eq(agent.id)
        end

        it 'preserves other content_attributes when adding feedback' do
          message.content_attributes = { 'other_data' => 'keep this', 'another_field' => 123 }
          message.save!

          feedback = {
            'rating' => 'positive',
            'agent_id' => agent.id,
            'created_at' => Time.current.utc.iso8601
          }

          message.content_attributes = message.content_attributes.merge('ai_feedback' => feedback)
          message.save!

          expect(message.content_attributes['ai_feedback']).to be_present
          expect(message.content_attributes['other_data']).to eq('keep this')
          expect(message.content_attributes['another_field']).to eq(123)
        end
      end

      context 'when updating existing AI feedback' do
        let(:original_feedback) do
          {
            'rating' => 'positive',
            'feedback_text' => 'Original feedback',
            'agent_id' => agent.id,
            'created_at' => 1.hour.ago.utc.iso8601
          }
        end

        before do
          message.content_attributes = message.content_attributes.merge('ai_feedback' => original_feedback)
          message.save!
        end

        it 'updates feedback while preserving created_at' do
          updated_feedback = original_feedback.merge(
            'rating' => 'negative',
            'feedback_text' => 'Updated feedback text',
            'updated_at' => Time.current.utc.iso8601
          )

          message.content_attributes = message.content_attributes.merge('ai_feedback' => updated_feedback)
          message.save!

          ai_feedback = message.content_attributes['ai_feedback']
          expect(ai_feedback['rating']).to eq('negative')
          expect(ai_feedback['feedback_text']).to eq('Updated feedback text')
          expect(ai_feedback['agent_id']).to eq(agent.id)
          expect(ai_feedback['created_at']).to eq(original_feedback['created_at'])
          expect(ai_feedback['updated_at']).to be_present
        end

        it 'allows partial updates' do
          updated_feedback = original_feedback.merge(
            'rating' => 'neutral',
            'updated_at' => Time.current.utc.iso8601
          )

          message.content_attributes = message.content_attributes.merge('ai_feedback' => updated_feedback)
          message.save!

          ai_feedback = message.content_attributes['ai_feedback']
          expect(ai_feedback['rating']).to eq('neutral')
          expect(ai_feedback['feedback_text']).to eq('Original feedback') # Unchanged
          expect(ai_feedback['created_at']).to eq(original_feedback['created_at'])
        end
      end

      context 'when removing AI feedback' do
        before do
          feedback = {
            'rating' => 'positive',
            'feedback_text' => 'Feedback to remove',
            'agent_id' => agent.id,
            'created_at' => Time.current.utc.iso8601
          }
          message.content_attributes = message.content_attributes.merge('ai_feedback' => feedback)
          message.save!
        end

        it 'removes AI feedback completely' do
          message.content_attributes = message.content_attributes.except('ai_feedback')
          message.save!

          expect(message.content_attributes['ai_feedback']).to be_nil
        end

        it 'preserves other content_attributes when removing feedback' do
          message.content_attributes = message.content_attributes.merge('other_data' => 'keep this')
          message.save!

          message.content_attributes = message.content_attributes.except('ai_feedback')
          message.save!

          expect(message.content_attributes['ai_feedback']).to be_nil
          expect(message.content_attributes['other_data']).to eq('keep this')
        end
      end
    end

    describe 'AI feedback validation and edge cases' do
      it 'handles empty content_attributes gracefully' do
        message.content_attributes = {}
        message.save!

        expect(message.content_attributes['ai_feedback']).to be_nil
        expect { message.save! }.not_to raise_error
      end

      it 'handles nil content_attributes gracefully' do
        message.content_attributes = nil
        message.save!

        expect(message.content_attributes).to eq({})
        expect { message.save! }.not_to raise_error
      end

      it 'preserves AI feedback through message updates' do
        feedback = {
          'rating' => 'positive',
          'feedback_text' => 'Great response',
          'agent_id' => agent.id,
          'created_at' => Time.current.utc.iso8601
        }

        message.content_attributes = message.content_attributes.merge('ai_feedback' => feedback)
        message.save!

        # Update other message attributes
        message.update!(content: 'Updated message content')

        message.reload
        expect(message.content_attributes['ai_feedback']).to be_present
        expect(message.content_attributes['ai_feedback']['rating']).to eq('positive')
      end

      it 'allows different rating values' do
        %w[positive negative neutral].each do |rating|
          feedback = {
            'rating' => rating,
            'agent_id' => agent.id,
            'created_at' => Time.current.utc.iso8601
          }

          message.content_attributes = message.content_attributes.merge('ai_feedback' => feedback)
          expect { message.save! }.not_to raise_error

          expect(message.content_attributes['ai_feedback']['rating']).to eq(rating)
        end
      end

      it 'handles long feedback text' do
        long_text = 'a' * 2000
        feedback = {
          'rating' => 'positive',
          'feedback_text' => long_text,
          'agent_id' => agent.id,
          'created_at' => Time.current.utc.iso8601
        }

        message.content_attributes = message.content_attributes.merge('ai_feedback' => feedback)
        expect { message.save! }.not_to raise_error

        expect(message.content_attributes['ai_feedback']['feedback_text']).to eq(long_text)
      end

      it 'handles special characters in feedback text' do
        special_text = 'Feedback with émojis 🤖 and symbols @#$%^&*()'
        feedback = {
          'rating' => 'positive',
          'feedback_text' => special_text,
          'agent_id' => agent.id,
          'created_at' => Time.current.utc.iso8601
        }

        message.content_attributes = message.content_attributes.merge('ai_feedback' => feedback)
        expect { message.save! }.not_to raise_error

        expect(message.content_attributes['ai_feedback']['feedback_text']).to eq(special_text)
      end
    end

    describe 'AI feedback query and retrieval' do
      it 'provides access to AI feedback data via Ruby hash operations' do
        feedback_data = {
          'rating' => 'positive',
          'feedback_text' => 'Test feedback',
          'agent_id' => agent.id,
          'created_at' => Time.current.utc.iso8601
        }

        message.content_attributes = message.content_attributes.merge('ai_feedback' => feedback_data)
        message.save!
        message.reload

        # Test accessing nested JSON values via Ruby hash
        expect(message.content_attributes['ai_feedback']).to be_present
        expect(message.content_attributes['ai_feedback']['rating']).to eq('positive')
        expect(message.content_attributes['ai_feedback']['feedback_text']).to eq('Test feedback')
        expect(message.content_attributes['ai_feedback']['agent_id']).to eq(agent.id)
      end

      it 'supports retrieving AI feedback using Hash dig method' do
        message.content_attributes = message.content_attributes.merge(
          'ai_feedback' => {
            'rating' => 'negative',
            'feedback_text' => 'Could be better',
            'agent_id' => admin.id,
            'created_at' => Time.current.utc.iso8601
          }
        )
        message.save!
        message.reload

        # Test accessing nested values using dig
        expect(message.content_attributes.dig('ai_feedback', 'rating')).to eq('negative')
        expect(message.content_attributes.dig('ai_feedback', 'feedback_text')).to eq('Could be better')
        expect(message.content_attributes.dig('ai_feedback', 'agent_id')).to eq(admin.id)
        expect(message.content_attributes.dig('ai_feedback', 'created_at')).to be_present
      end

      it 'maintains data integrity through save and reload cycles' do
        original_feedback = {
          'rating' => 'positive',
          'feedback_text' => 'Excellent AI response',
          'agent_id' => agent.id,
          'created_at' => Time.current.utc.iso8601
        }

        message.content_attributes = message.content_attributes.merge('ai_feedback' => original_feedback)
        message.save!

        # Reload from database and verify data integrity
        reloaded_message = Message.find(message.id)
        ai_feedback = reloaded_message.content_attributes['ai_feedback']

        expect(ai_feedback['rating']).to eq(original_feedback['rating'])
        expect(ai_feedback['feedback_text']).to eq(original_feedback['feedback_text'])
        expect(ai_feedback['agent_id']).to eq(original_feedback['agent_id'])
        expect(ai_feedback['created_at']).to eq(original_feedback['created_at'])
      end
    end
  end

  describe 'notification forwarding' do
    let!(:account) { create(:account, custom_attributes: { 'store_id' => 'test_store_123' }) }
    let!(:user) { create(:user, account: account) }
    let!(:inbox) { create(:inbox, account: account) }
    let!(:conversation) { create(:conversation, account: account, inbox: inbox) }
    let(:forward_service_double) { instance_double(ForwardNotificationService) }

    before do
      # Mock the global namespace version that the callback uses
      allow(::ForwardNotificationService).to receive(:new).and_return(forward_service_double)
      allow(forward_service_double).to receive(:send_notification)
    end

    describe '#notification_format?' do
      context 'when message matches notification format' do
        it 'returns true for valid notification format' do
          message = build(:message, content: '[urgent] This is urgent', conversation: conversation, account: account)
          expect(message.send(:notification_format?)).to be true
        end

        it 'returns true for different notification types' do
          message = build(:message, content: '[alert] System alert', conversation: conversation, account: account)
          expect(message.send(:notification_format?)).to be true
        end

        it 'returns true for notification with spaces in type' do
          message = build(:message, content: '[system alert] Important message', conversation: conversation, account: account)
          expect(message.send(:notification_format?)).to be true
        end
      end

      context 'when message does not match notification format' do
        it 'returns false for regular messages' do
          message = build(:message, content: 'This is a regular message', conversation: conversation, account: account)
          expect(message.send(:notification_format?)).to be false
        end

        it 'returns false for malformed notification format' do
          message = build(:message, content: '[incomplete notification', conversation: conversation, account: account)
          expect(message.send(:notification_format?)).to be false
        end

        it 'returns false for empty brackets' do
          message = build(:message, content: '[]: Empty brackets', conversation: conversation, account: account)
          expect(message.send(:notification_format?)).to be false
        end
      end
    end

    describe '#trigger_notification_forwarding' do
      context 'when all conditions are met' do
        let(:notification_message) do
          create(:message,
                 content: '[test] This is a test notification',
                 conversation: conversation,
                 account: account,
                 message_type: 'outgoing',
                 private: true,
                 sender: user)
        end

        it 'creates and calls ForwardNotificationService' do
          notification_message # trigger the callback

          expect(::ForwardNotificationService).to have_received(:new).with(notification_message)
          expect(forward_service_double).to have_received(:send_notification)
        end
      end

      context 'when message is not private' do
        let(:public_message) do
          create(:message,
                 content: '[test] This is a test notification',
                 conversation: conversation,
                 account: account,
                 message_type: 'outgoing',
                 private: false,
                 sender: user)
        end

        it 'does not trigger forwarding service' do
          public_message # trigger the callback

          expect(::ForwardNotificationService).not_to have_received(:new)
          expect(forward_service_double).not_to have_received(:send_notification)
        end
      end

      context 'when message is not outgoing' do
        let(:incoming_message) do
          create(:message,
                 content: '[test] This is a test notification',
                 conversation: conversation,
                 account: account,
                 message_type: 'incoming',
                 private: true)
        end

        it 'does not trigger forwarding service' do
          incoming_message # trigger the callback

          expect(::ForwardNotificationService).not_to have_received(:new)
          expect(forward_service_double).not_to have_received(:send_notification)
        end
      end

      context 'when message does not match notification format' do
        let(:regular_message) do
          create(:message,
                 content: 'This is a regular private message',
                 conversation: conversation,
                 account: account,
                 message_type: 'outgoing',
                 private: true,
                 sender: user)
        end

        it 'does not trigger forwarding service' do
          regular_message # trigger the callback

          expect(::ForwardNotificationService).not_to have_received(:new)
          expect(forward_service_double).not_to have_received(:send_notification)
        end
      end

      context 'when ForwardNotificationService raises an error' do
        before do
          allow(forward_service_double).to receive(:send_notification).and_raise(StandardError, 'Service error')
          allow(Rails.logger).to receive(:error)
        end

        let(:error_message) do
          create(:message,
                 content: '[test] This will cause an error',
                 conversation: conversation,
                 account: account,
                 message_type: 'outgoing',
                 private: true,
                 sender: user)
        end

        it 'logs the error and does not re-raise' do
          expect { error_message }.not_to raise_error

          expect(Rails.logger).to have_received(:error).with('Error in trigger_notification_forwarding: Service error')
        end
      end
    end

    describe 'after_create_commit callbacks' do
      it 'includes trigger_notification_forwarding callback' do
        expect(Message._commit_callbacks.select { |cb| cb.filter == :trigger_notification_forwarding }).not_to be_empty
      end

      it 'triggers callback after message creation' do
        allow_any_instance_of(Message).to receive(:trigger_notification_forwarding)

        message = create(:message, conversation: conversation, account: account)

        expect(message).to have_received(:trigger_notification_forwarding)
      end
    end
  end
end
