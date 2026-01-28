require 'rails_helper'

describe ReportingEventListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }
  let!(:message) do
    create(:message, message_type: 'outgoing',
                     account: account, inbox: inbox, conversation: conversation)
  end

  # Create inbox membership for user
  before do
    create(:inbox_member, user: user, inbox: inbox)
  end

  describe '#conversation_resolved' do
    let!(:resolved_conversation) do
      create(:conversation, account: account, inbox: inbox, assignee: user)
    end

    before do
      # Create conversation participant for the resolved conversation
      create(:conversation_participant, conversation: resolved_conversation, user: user)
      # Update status to resolved - this will automatically set resolved_at via callback
      resolved_conversation.update!(status: :resolved)
    end

    it 'creates conversation_resolved event' do
      expect(account.reporting_events.where(name: 'conversation_resolved').count).to be 0
      event = Events::Base.new('conversation.resolved', Time.zone.now, conversation: resolved_conversation)
      listener.conversation_resolved(event)
      expect(account.reporting_events.where(name: 'conversation_resolved').count).to be 1
    end

    context 'when business hours enabled for inbox' do
      let(:created_at) { Time.zone.parse('March 20, 2022 00:00') }
      let(:resolved_at) { Time.zone.parse('March 26, 2022 23:59') }
      let!(:new_inbox) { create(:inbox, working_hours_enabled: true, account: account) }
      let!(:new_conversation) do
        create(:conversation, created_at: created_at, account: account, inbox: new_inbox, assignee: user)
      end

      before do
        create(:inbox_member, user: user, inbox: new_inbox)
        create(:conversation_participant, conversation: new_conversation, user: user)
        # Manually set resolved_at to specific time for business hours calculation
        # rubocop:disable Rails/SkipsModelValidations
        new_conversation.update_column(:resolved_at, resolved_at)
        new_conversation.update_column(:status, 1) # 1 = resolved
        # rubocop:enable Rails/SkipsModelValidations
        new_conversation.reload
      end

      it 'creates conversation_resolved event with business hour value' do
        event = Events::Base.new('conversation.resolved', Time.zone.now, conversation: new_conversation)
        listener.conversation_resolved(event)
        expect(account.reporting_events.where(name: 'conversation_resolved').first.value_in_business_hours).to be 144_000.0
      end
    end

    describe 'conversation_bot_resolved' do
      let!(:agent_bot_inbox) { create(:inbox, account: account) }
      let!(:agent_bot) { create(:agent_bot, account: account) }
      let!(:bot_resolved_conversation) do
        create(:conversation, account: account, inbox: agent_bot_inbox, assignee: user)
      end

      before do
        create(:inbox_member, user: user, inbox: agent_bot_inbox)
        create(:agent_bot_inbox, agent_bot: agent_bot, inbox: agent_bot_inbox)
        create(:conversation_participant, conversation: bot_resolved_conversation, user: user)
        # Update status to resolved
        bot_resolved_conversation.update!(status: :resolved)
      end

      it 'creates a conversation_bot_resolved event if resolved conversation does not have human interaction' do
        event = Events::Base.new('conversation.resolved', Time.zone.now, conversation: bot_resolved_conversation)
        listener.conversation_resolved(event)
        expect(account.reporting_events.where(name: 'conversation_bot_resolved').count).to be 1
      end

      it 'does not create a conversation_bot_resolved event if resolved conversation inbox does not have active bot' do
        bot_resolved_conversation.update(inbox: inbox)
        bot_resolved_conversation.update!(status: :resolved)
        event = Events::Base.new('conversation.resolved', Time.zone.now, conversation: bot_resolved_conversation)
        listener.conversation_resolved(event)
        expect(account.reporting_events.where(name: 'conversation_bot_resolved').count).to be 0
      end

      it 'does not create a conversation_bot_resolved event if resolved conversation has human interaction' do
        create(:message, message_type: 'outgoing', sender_type: 'User', account: account, inbox: agent_bot_inbox,
                         conversation: bot_resolved_conversation)
        event = Events::Base.new('conversation.resolved', Time.zone.now, conversation: bot_resolved_conversation)
        listener.conversation_resolved(event)
        expect(account.reporting_events.where(name: 'conversation_bot_resolved').count).to be 0
      end
    end
  end

  describe '#reply_created' do
    let(:contact) { create(:contact, account: account) }

    def create_customer_message(conversation, created_at: Time.current)
      create(:message,
             message_type: 'incoming',
             account: account,
             inbox: inbox,
             conversation: conversation,
             sender: contact,
             created_at: created_at)
    end

    def create_agent_message(conversation, created_at: Time.current, sender: user)
      create(:message,
             message_type: 'outgoing',
             sender_type: 'User',
             account: account,
             inbox: inbox,
             conversation: conversation,
             sender: sender,
             created_at: created_at)
    end

    def create_reply_event(agent_message, waiting_since, event_time = nil)
      Events::Base.new('reply.created', event_time || agent_message.created_at,
                       waiting_since: waiting_since,
                       message: agent_message)
    end

    it 'creates reply created event' do
      participant_created_at = 2.5.hours.ago
      customer_message_time = 2.hours.ago
      agent_message_time = Time.current

      # Create participant
      create(:conversation_participant, conversation: message.conversation, user: user, created_at: participant_created_at)

      # Create customer message
      create_customer_message(message.conversation, created_at: customer_message_time)

      # Create agent message
      agent_msg = create_agent_message(message.conversation, created_at: agent_message_time)

      event = Events::Base.new('reply.created', agent_message_time, waiting_since: customer_message_time, message: agent_msg)
      listener.reply_created(event)

      events = account.reporting_events.where(name: 'reply_time', conversation_id: message.conversation_id)
      expect(events.length).to be 1
      expect(events.first.value).to be_within(1).of(7200)
    end

    context 'when conversation is reopened' do
      let(:resolved_conversation) do
        create(:conversation, account: account, inbox: inbox, assignee: user,
                              status: 'resolved', contact: contact)
      end

      context 'when customer sends message after resolution' do
        it 'calculates reply time from the reopening message' do
          participant_created_at = 3.5.hours.ago
          customer_message_time = 3.hours.ago
          agent_reply_time = 1.hour.ago

          create(:conversation_participant, conversation: resolved_conversation, user: user, created_at: participant_created_at)

          create_customer_message(resolved_conversation, created_at: customer_message_time)

          resolved_conversation.reload
          expect(resolved_conversation.status).to eq('open')

          agent_message = create_agent_message(resolved_conversation, created_at: agent_reply_time)

          event = create_reply_event(agent_message, customer_message_time)
          listener.reply_created(event)

          events = account.reporting_events.where(name: 'reply_time', conversation_id: resolved_conversation.id)
          expect(events.length).to be 1
          expect(events.first.value).to be_within(60).of(7200)
        end
      end

      context 'when conversation has multiple reopenings' do
        it 'tracks reply time correctly for each reopening' do
          # First cycle - create participant, customer message, and agent reply
          first_participant = create(:conversation_participant, conversation: resolved_conversation, user: user, created_at: 5.hours.ago)

          create_customer_message(resolved_conversation, created_at: 4.5.hours.ago)
          first_agent_reply = create_agent_message(resolved_conversation, created_at: 4.hours.ago)

          event = create_reply_event(first_agent_reply, 4.5.hours.ago)
          listener.reply_created(event)

          # Verify first reply time was created
          events = account.reporting_events.where(name: 'reply_time', conversation_id: resolved_conversation.id)
          expect(events.length).to be 1
          expect(events.first.value).to be_within(60).of(1800) # 30 minutes

          # Close the first participant
          # rubocop:disable Rails/SkipsModelValidations
          first_participant.update_column(:left_at, 3.5.hours.ago)
          # rubocop:enable Rails/SkipsModelValidations

          # Second cycle - create new participant for reopening
          second_user = create(:user, account: account)
          create(:inbox_member, user: second_user, inbox: inbox)
          create(:conversation_participant, conversation: resolved_conversation, user: second_user, created_at: 2.hours.ago)

          create_customer_message(resolved_conversation, created_at: 1.5.hours.ago)
          second_agent_reply = create_agent_message(resolved_conversation, created_at: 1.hour.ago, sender: second_user)

          event = create_reply_event(second_agent_reply, 1.5.hours.ago)
          listener.reply_created(event)

          # Verify both reply times were created
          events = account.reporting_events.where(name: 'reply_time', conversation_id: resolved_conversation.id)
                          .order(created_at: :asc)
          expect(events.length).to be 2
          expect(events.first.value).to be_within(60).of(1800)  # 30 minutes
          expect(events.second.value).to be_within(60).of(1800) # 30 minutes
        end
      end

      context 'when conversation is manually reopened' do
        it 'sets waiting_since when first customer message arrives after manual reopening' do
          participant_created_at = 1.5.hours.ago

          resolved_conversation.update!(status: 'open')

          create(:conversation_participant, conversation: resolved_conversation, user: user, created_at: participant_created_at)

          customer_message_time = 1.hour.ago
          create_customer_message(resolved_conversation, created_at: customer_message_time)

          agent_reply_time = 15.minutes.ago
          agent_message = create_agent_message(resolved_conversation, created_at: agent_reply_time)

          event = create_reply_event(agent_message, customer_message_time)
          listener.reply_created(event)

          events = account.reporting_events.where(name: 'reply_time', conversation_id: resolved_conversation.id)
          expect(events.length).to be 1
          expect(events.first.value).to be_within(60).of(2700)
        end
      end

      context 'when waiting_since is nil' do
        it 'does not creates reply time events' do
          create(:conversation_participant, conversation: resolved_conversation, user: user)

          agent_message = create_agent_message(resolved_conversation)

          event = create_reply_event(agent_message, nil)
          listener.reply_created(event)

          events = account.reporting_events.where(name: 'reply_time', conversation_id: resolved_conversation.id)
          expect(events.length).to be 0
        end
      end
    end
  end

  describe '#first_reply_created' do
    it 'creates first_response event' do
      participant_created_at = 1.hour.ago
      message_created_at = Time.current

      # Update message timestamp
      message.update(created_at: message_created_at, sender_type: 'User', sender_id: user.id)

      # Create participant
      create(:conversation_participant, conversation: message.conversation, user: user, created_at: participant_created_at)

      previous_count = account.reporting_events.where(name: 'first_response').count
      event = Events::Base.new('first.reply.created', message_created_at, message: message)
      listener.first_reply_created(event)
      expect(account.reporting_events.where(name: 'first_response').count).to eql previous_count + 1
    end

    context 'when business hours enabled for inbox' do
      let(:participant_created_at) { Time.zone.parse('March 20, 2022 00:00') }
      let(:message_created_at) { Time.zone.parse('March 26, 2022 23:59') }
      let!(:new_inbox) { create(:inbox, working_hours_enabled: true, account: account) }
      let!(:new_conversation) do
        create(:conversation, created_at: participant_created_at, account: account, inbox: new_inbox, assignee: user)
      end
      let!(:new_message) do
        create(:message, message_type: 'outgoing', sender_type: 'User', created_at: message_created_at,
                         account: account, inbox: new_inbox, conversation: new_conversation, sender: user)
      end

      before do
        create(:inbox_member, user: user, inbox: new_inbox)
        create(:conversation_participant, conversation: new_conversation, user: user, created_at: participant_created_at)
      end

      it 'creates first_response event with business hour value' do
        event = Events::Base.new('first.reply.created', message_created_at, message: new_message)
        listener.first_reply_created(event)
        reporting_event = account.reporting_events.where(name: 'first_response').first
        expect(reporting_event.value_in_business_hours).to be 144_000.0
        expect(reporting_event.user_id).to be user.id
      end
    end

    context 'when last handoff event exists' do
      let(:now) { Time.zone.now }
      let(:conversation_updated_at) { now + 20.seconds }
      let(:participant_created_at) { now + 20.seconds }
      let(:human_message_created_at) { now + 62.seconds }
      let(:new_conversation) { create(:conversation, account: account, inbox: inbox, assignee: user, updated_at: conversation_updated_at) }
      let(:new_message) do
        create(:message, message_type: 'outgoing', sender_type: 'User', created_at: human_message_created_at, account: account, inbox: inbox,
                         conversation: new_conversation, sender: user)
      end

      before do
        create(:conversation_participant, conversation: new_conversation, user: user, created_at: participant_created_at)
      end

      it 'creates first_response event with correct value' do
        # this will create a handoff event
        event = Events::Base.new('conversation.bot_handoff', conversation_updated_at, conversation: new_conversation)
        listener.conversation_bot_handoff(event)

        # create the first reply event
        event = Events::Base.new('first.reply.created', human_message_created_at, message: new_message)
        listener.first_reply_created(event)

        reporting_event = account.reporting_events.where(name: 'first_response').first
        expect(reporting_event.value).to be 42.0
      end
    end
  end

  describe '#conversation_bot_handoff' do
    it 'creates conversation_bot_handoff event only once' do
      expect(account.reporting_events.where(name: 'conversation_bot_handoff').count).to be 0
      event = Events::Base.new('conversation.bot_handoff', Time.zone.now, conversation: conversation)
      listener.conversation_bot_handoff(event)
      expect(account.reporting_events.where(name: 'conversation_bot_handoff').count).to be 1

      # add extra handoff event for the same and ensure it's not created
      event = Events::Base.new('conversation.bot_handoff', Time.zone.now, conversation: conversation)
      listener.conversation_bot_handoff(event)
      expect(account.reporting_events.where(name: 'conversation_bot_handoff').count).to be 1
    end

    context 'when business hours enabled for inbox' do
      let(:created_at) { Time.zone.parse('March 20, 2022 00:00') }
      let(:updated_at) { Time.zone.parse('March 26, 2022 23:59') }
      let!(:new_inbox) { create(:inbox, working_hours_enabled: true, account: account) }
      let!(:new_conversation) do
        create(:conversation, created_at: created_at, updated_at: updated_at, account: account, inbox: new_inbox, assignee: user)
      end

      before do
        create(:inbox_member, user: user, inbox: new_inbox)
      end

      it 'creates conversation_bot_handoff event with business hour value' do
        event = Events::Base.new('conversation.bot_handoff', Time.zone.now, conversation: new_conversation)
        listener.conversation_bot_handoff(event)
        expect(account.reporting_events.where(name: 'conversation_bot_handoff').first.value_in_business_hours).to be 144_000.0
      end
    end
  end

  describe '#conversation_opened' do
    context 'when conversation is opened for the first time' do
      let(:new_conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }

      it 'creates conversation_opened event with value 0' do
        expect(account.reporting_events.where(name: 'conversation_opened').count).to be 0
        event = Events::Base.new('conversation.opened', Time.zone.now, conversation: new_conversation)
        listener.conversation_opened(event)
        expect(account.reporting_events.where(name: 'conversation_opened').count).to be 1

        opened_event = account.reporting_events.where(name: 'conversation_opened').first
        expect(opened_event.value).to eq 0
        expect(opened_event.value_in_business_hours).to eq 0
        expect(opened_event.event_start_time).to be_within(1.second).of(new_conversation.created_at)
        expect(opened_event.event_end_time).to be_within(1.second).of(new_conversation.updated_at)
      end
    end

    context 'when conversation is reopened after being resolved' do
      let(:resolved_time) { 2.hours.ago }
      let(:reopened_time) { 1.hour.ago }
      let(:reopened_conversation) do
        create(:conversation, account: account, inbox: inbox, assignee: user, updated_at: reopened_time)
      end

      before do
        # Create a resolved event first
        create(:reporting_event,
               name: 'conversation_resolved',
               account_id: account.id,
               inbox_id: inbox.id,
               conversation_id: reopened_conversation.id,
               user_id: user.id,
               value: 3600,
               event_start_time: reopened_conversation.created_at,
               event_end_time: resolved_time)
      end

      it 'creates conversation_opened event' do
        expect(account.reporting_events.where(name: 'conversation_opened').count).to be 0
        event = Events::Base.new('conversation.opened', reopened_time, conversation: reopened_conversation)
        listener.conversation_opened(event)
        expect(account.reporting_events.where(name: 'conversation_opened').count).to be 1
      end

      it 'calculates correct time since resolution' do
        event = Events::Base.new('conversation.opened', reopened_time, conversation: reopened_conversation)
        listener.conversation_opened(event)

        reopened_event = account.reporting_events.where(name: 'conversation_opened').first
        expect(reopened_event.value).to be_within(1).of(3600) # 1 hour = 3600 seconds
        expect(reopened_event.event_start_time).to be_within(1.second).of(resolved_time)
        expect(reopened_event.event_end_time).to be_within(1.second).of(reopened_time)
      end

      it 'sets correct attributes for conversation_opened event' do
        event = Events::Base.new('conversation.opened', reopened_time, conversation: reopened_conversation)
        listener.conversation_opened(event)

        reopened_event = account.reporting_events.where(name: 'conversation_opened').first
        expect(reopened_event.account_id).to eq(account.id)
        expect(reopened_event.inbox_id).to eq(inbox.id)
        expect(reopened_event.conversation_id).to eq(reopened_conversation.id)
        expect(reopened_event.user_id).to eq(user.id)
      end

      context 'when business hours enabled for inbox' do
        let(:resolved_time) { Time.zone.parse('March 20, 2022 12:00') }
        let(:reopened_time) { Time.zone.parse('March 21, 2022 14:00') }
        let!(:business_hours_inbox) { create(:inbox, working_hours_enabled: true, account: account) }
        let!(:business_hours_conversation) do
          create(:conversation, account: account, inbox: business_hours_inbox, assignee: user, updated_at: reopened_time)
        end

        before do
          create(:inbox_member, user: user, inbox: business_hours_inbox)
          create(:reporting_event,
                 name: 'conversation_resolved',
                 account_id: account.id,
                 inbox_id: business_hours_inbox.id,
                 conversation_id: business_hours_conversation.id,
                 user_id: user.id,
                 value: 3600,
                 event_start_time: business_hours_conversation.created_at,
                 event_end_time: resolved_time)
        end

        it 'creates conversation_opened event with business hour value' do
          event = Events::Base.new('conversation.opened', reopened_time, conversation: business_hours_conversation)
          listener.conversation_opened(event)

          reopened_event = account.reporting_events.where(name: 'conversation_opened').first
          expect(reopened_event.value_in_business_hours).to be 18_000.0 # 5 business hours (26 hours total - 21 non-business hours)
        end
      end
    end

    context 'when conversation has multiple resolutions' do
      let(:first_resolved_time) { 3.hours.ago }
      let(:second_resolved_time) { 1.hour.ago }
      let(:reopened_time) { 30.minutes.ago }
      let(:multiple_resolution_conversation) do
        create(:conversation, account: account, inbox: inbox, assignee: user, updated_at: reopened_time)
      end

      before do
        # Create first resolved event
        create(:reporting_event,
               name: 'conversation_resolved',
               account_id: account.id,
               inbox_id: inbox.id,
               conversation_id: multiple_resolution_conversation.id,
               user_id: user.id,
               value: 3600,
               event_start_time: multiple_resolution_conversation.created_at,
               event_end_time: first_resolved_time)

        # Create second resolved event (more recent)
        create(:reporting_event,
               name: 'conversation_resolved',
               account_id: account.id,
               inbox_id: inbox.id,
               conversation_id: multiple_resolution_conversation.id,
               user_id: user.id,
               value: 1800,
               event_start_time: first_resolved_time,
               event_end_time: second_resolved_time)
      end

      it 'uses the most recent resolved event for calculation' do
        event = Events::Base.new('conversation.opened', reopened_time, conversation: multiple_resolution_conversation)
        listener.conversation_opened(event)

        reopened_event = account.reporting_events.where(name: 'conversation_opened').first
        expect(reopened_event.value).to be_within(1).of(1800) # 30 minutes from second resolution
        expect(reopened_event.event_start_time).to be_within(1.second).of(second_resolved_time)
      end
    end

    context 'when agent bot resolves and conversation is reopened' do
      let(:agent_bot) { create(:agent_bot, account: account) }
      let(:agent_bot_inbox) { create(:inbox, account: account) }
      let(:bot_resolved_time) { 2.hours.ago }
      let(:reopened_time) { 1.hour.ago }
      let(:bot_conversation) do
        create(:conversation, account: account, inbox: agent_bot_inbox, assignee: user, updated_at: reopened_time)
      end

      before do
        create(:inbox_member, user: user, inbox: agent_bot_inbox)
        create(:agent_bot_inbox, agent_bot: agent_bot, inbox: agent_bot_inbox)

        create(:reporting_event,
               name: 'conversation_resolved',
               account_id: account.id,
               inbox_id: agent_bot_inbox.id,
               conversation_id: bot_conversation.id,
               user_id: user.id,
               event_end_time: bot_resolved_time)
      end

      it 'creates conversation_opened event for agent bot reopening' do
        event = Events::Base.new('conversation.opened', reopened_time, conversation: bot_conversation)
        listener.conversation_opened(event)

        reopened_event = account.reporting_events.where(name: 'conversation_opened').first
        expect(reopened_event.value).to be_within(1).of(3600) # 1 hour since resolution
        expect(reopened_event.event_start_time).to be_within(1.second).of(bot_resolved_time)
        expect(reopened_event.event_end_time).to be_within(1.second).of(reopened_time)
      end
    end
  end
end
