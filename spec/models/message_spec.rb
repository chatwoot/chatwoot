# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join 'spec/models/concerns/liquidable_shared.rb'

RSpec.describe Message do
  before do
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(described_class).to receive(:reindex_for_search).and_return(true)
    # rubocop:enable RSpec/AnyInstance
  end

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

      context 'when skip_message_flooding_validation is set' do
        it 'skips message flooding validation when set to true' do
          with_modified_env 'CONVERSATION_MESSAGE_PER_MINUTE_LIMIT': '2' do
            conversation = message.conversation
            create(:message, conversation: conversation)
            conv_new_message = build(:message, conversation: message.conversation)

            expect(conv_new_message.valid?).to be false
            expect(conv_new_message.errors[:base]).to eq(['Too many messages'])

            conv_new_message.skip_message_flooding_validation = true
            conv_new_message.valid?
            expect(conv_new_message.errors[:base]).to be_empty
            expect(conv_new_message.valid?).to be true
          end
        end

        it 'still validates other attributes when message flooding is skipped' do
          message_without_required_fields = build(:message)
          message_without_required_fields.account_id = nil
          message_without_required_fields.inbox_id = nil
          message_without_required_fields.skip_message_flooding_validation = true

          expect(message_without_required_fields.valid?).to be false
          expect(message_without_required_fields.errors[:account_id]).to include("can't be blank")
          expect(message_without_required_fields.errors[:inbox_id]).to include("can't be blank")
        end

        it 'allows bulk message creation when skip_message_flooding_validation is true' do
          with_modified_env 'CONVERSATION_MESSAGE_PER_MINUTE_LIMIT': '2' do
            conversation = message.conversation

            messages_to_create = 5
            created_messages = []

            messages_to_create.times do |i|
              new_message = build(:message,
                                  conversation: conversation,
                                  content: "Bulk message #{i + 1}")
              new_message.skip_message_flooding_validation = true

              expect(new_message.valid?).to be true
              new_message.save!
              created_messages << new_message
            end

            expect(created_messages.count).to eq(messages_to_create)
            expect(conversation.messages.count).to eq(messages_to_create + 1)
          end
        end
      end
    end

    context 'when it validates source_id length' do
      it 'valid when source_id is within text limit (20000 chars)' do
        long_source_id = 'a' * 10_000
        message.source_id = long_source_id
        expect(message.valid?).to be true
      end

      it 'valid when source_id is exactly 20000 characters' do
        long_source_id = 'a' * 20_000
        message.source_id = long_source_id
        expect(message.valid?).to be true
      end

      it 'invalid when source_id exceeds text limit (20000 chars)' do
        long_source_id = 'a' * 20_001
        message.source_id = long_source_id
        message.valid?

        expect(message.errors[:source_id]).to include('is too long (maximum is 20000 characters)')
      end

      it 'handles long email Message-ID headers correctly' do
        # Simulate a long Message-ID like some email systems generate
        long_message_id = "msg-#{SecureRandom.hex(240)}@verylongdomainname.example.com"[0...500]
        message.source_id = long_message_id
        message.content_type = 'incoming_email'

        expect(message.valid?).to be true
        expect(message.source_id.length).to eq(500)
      end

      it 'allows nil source_id' do
        message.source_id = nil
        expect(message.valid?).to be true
      end

      it 'allows empty string source_id' do
        message.source_id = ''
        expect(message.valid?).to be true
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
      conversation.update!(waiting_since: nil)
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

    context 'when bot has responded to the conversation' do
      let(:agent_bot) { create(:agent_bot, account: conversation.account) }

      before do
        # Create initial customer message
        create(:message, conversation: conversation, message_type: :incoming,
                         created_at: 2.hours.ago)
        conversation.update!(waiting_since: 2.hours.ago)

        # Bot responds
        create(:message, conversation: conversation, message_type: :outgoing,
                         sender: agent_bot, created_at: 1.hour.ago)
      end

      it 'resets waiting_since when customer sends a new message after bot response' do
        new_message = build(:message, conversation: conversation, message_type: :incoming)
        new_message.save!

        conversation.reload
        expect(conversation.waiting_since).to be_within(1.second).of(new_message.created_at)
      end

      it 'does not reset waiting_since if last response was from human agent' do
        # Human agent responds (clears waiting_since)
        create(:message, conversation: conversation, message_type: :outgoing,
                         sender: agent)
        conversation.reload
        expect(conversation.waiting_since).to be_nil

        # Customer sends new message
        new_message = build(:message, conversation: conversation, message_type: :incoming)
        new_message.save!

        conversation.reload
        expect(conversation.waiting_since).to be_within(1.second).of(new_message.created_at)
      end

      it 'clears waiting_since when bot responds' do
        # After the bot response in before block, waiting_since should already be cleared
        conversation.reload
        expect(conversation.waiting_since).to be_nil

        # Customer sends another message
        create(:message, conversation: conversation, message_type: :incoming,
                         created_at: 30.minutes.ago)
        conversation.reload
        expect(conversation.waiting_since).to be_within(1.second).of(30.minutes.ago)

        # Another bot response should clear it again
        create(:message, conversation: conversation, message_type: :outgoing,
                         sender: agent_bot, created_at: 15.minutes.ago)

        conversation.reload
        expect(conversation.waiting_since).to be_nil
      end
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
      let(:inbox_with_continuity) do
        create(:inbox, account: message.account,
                       channel: build(:channel_widget, account: message.account, continuity_via_email: true))
      end

      it 'schedules email notification for outgoing messages in website channel' do
        message.inbox = inbox_with_continuity
        message.conversation.update!(inbox: inbox_with_continuity)
        message.conversation.contact.update!(email: 'test@example.com')
        message.message_type = 'outgoing'

        ActiveJob::Base.queue_adapter = :test
        allow(Redis::Alfred).to receive(:set).and_return(true)
        perform_enqueued_jobs(only: SendReplyJob) do
          expect { message.save! }.to have_enqueued_job(ConversationReplyEmailJob).with(message.conversation.id, kind_of(Integer)).on_queue('mailers')
        end
      end

      it 'does not schedule email for website channel if continuity is disabled' do
        inbox_without_continuity = create(:inbox, account: message.account,
                                                  channel: build(:channel_widget, account: message.account, continuity_via_email: false))
        message.inbox = inbox_without_continuity
        message.conversation.update!(inbox: inbox_without_continuity)
        message.conversation.contact.update!(email: 'test@example.com')
        message.message_type = 'outgoing'

        ActiveJob::Base.queue_adapter = :test
        expect { message.save! }.not_to have_enqueued_job(ConversationReplyEmailJob)
      end

      it 'does not schedule email for private notes' do
        message.inbox = inbox_with_continuity
        message.conversation.update!(inbox: inbox_with_continuity)
        message.conversation.contact.update!(email: 'test@example.com')
        message.private = true
        message.message_type = 'outgoing'

        ActiveJob::Base.queue_adapter = :test
        expect { message.save! }.not_to have_enqueued_job(ConversationReplyEmailJob)
      end

      it 'calls SendReplyJob for all channels' do
        allow(SendReplyJob).to receive(:perform_later).and_return(true)
        message.message_type = 'outgoing'
        message.save!
        expect(SendReplyJob).to have_received(:perform_later).with(message.id)
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
      account.enable_features('advanced_search_indexing')
    end

    context 'when advanced search is not allowed globally' do
      before do
        allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(false)
      end

      it 'returns false' do
        expect(message.should_index?).to be false
      end
    end

    context 'when advanced search feature is not enabled for account on chatwoot cloud' do
      before do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
        account.disable_features('advanced_search_indexing')
      end

      it 'returns false' do
        expect(message.should_index?).to be false
      end
    end

    context 'when advanced search feature is not enabled for account on self-hosted' do
      before do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)
        account.disable_features('advanced_search_indexing')
      end

      it 'returns true' do
        expect(message.should_index?).to be true
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

  describe '#reindex_for_search callback' do
    let(:account) { create(:account) }
    let(:conversation) { create(:conversation, account: account) }

    before do
      allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true)
      account.enable_features('advanced_search_indexing')
    end

    context 'when message should be indexed' do
      it 'calls reindex_for_search for incoming message on create' do
        message = build(:message, conversation: conversation, account: account, message_type: :incoming)
        expect(message).to receive(:reindex_for_search)
        message.save!
      end

      it 'calls reindex_for_search for outgoing message on update' do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(described_class).to receive(:reindex_for_search).and_return(true)
        # rubocop:enable RSpec/AnyInstance
        message = create(:message, conversation: conversation, account: account, message_type: :outgoing)
        expect(message).to receive(:reindex_for_search).and_return(true)
        message.update!(content: 'Updated content')
      end
    end

    context 'when message should not be indexed' do
      it 'does not call reindex_for_search for activity message' do
        message = build(:message, conversation: conversation, account: account, message_type: :activity)
        expect(message).not_to receive(:reindex_for_search)
        message.save!
      end

      it 'does not call reindex_for_search for unpaid account on cloud' do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
        account.disable_features('advanced_search_indexing')
        message = build(:message, conversation: conversation, account: account, message_type: :incoming)
        expect(message).not_to receive(:reindex_for_search)
        message.save!
      end

      it 'does not call reindex_for_search when advanced search is not allowed' do
        allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(false)
        message = build(:message, conversation: conversation, account: account, message_type: :incoming)
        expect(message).not_to receive(:reindex_for_search)
        message.save!
      end
    end
  end
end
