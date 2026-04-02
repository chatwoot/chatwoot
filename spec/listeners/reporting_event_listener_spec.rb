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

  describe '#conversation_resolved' do
    it 'creates conversation_resolved event' do
      expect(account.reporting_events.where(name: 'conversation_resolved').count).to be 0
      event = Events::Base.new('conversation.resolved', Time.zone.now, conversation: conversation)
      listener.conversation_resolved(event)
      expect(account.reporting_events.where(name: 'conversation_resolved').count).to be 1
    end

    context 'when rollup creation fails' do
      let(:event) { Events::Base.new('conversation.resolved', Time.zone.now, conversation: conversation) }
      let(:error) { StandardError.new('rollup failed') }
      let(:exception_tracker) { instance_double(ChatwootExceptionTracker, capture_exception: true) }

      before do
        allow(ReportingEvents::RollupService).to receive(:perform).and_raise(error)
        allow(ChatwootExceptionTracker).to receive(:new).and_return(exception_tracker)
      end

      it 'captures the error without interrupting raw event creation' do
        expect { listener.conversation_resolved(event) }.not_to raise_error
        expect(ChatwootExceptionTracker).to have_received(:new).with(error, account: account)
        expect(account.reporting_events.where(name: 'conversation_resolved').count).to be 1
      end
    end

    context 'when business hours enabled for inbox' do
      let(:created_at) { Time.zone.parse('March 20, 2022 00:00') }
      let(:updated_at) { Time.zone.parse('March 26, 2022 23:59') }
      let!(:new_inbox) { create(:inbox, working_hours_enabled: true, account: account) }
      let!(:new_conversation) do
        create(:conversation, created_at: created_at, updated_at: updated_at, account: account, inbox: new_inbox, assignee: user)
      end

      it 'creates conversation_resolved event with business hour value' do
        event = Events::Base.new('conversation.resolved', updated_at, conversation: new_conversation)
        listener.conversation_resolved(event)
        expect(account.reporting_events.where(name: 'conversation_resolved')[0]['value_in_business_hours']).to be 144_000.0
      end
    end

    it 'uses event timestamp even when conversation updated_at changes later' do
      resolved_at = conversation.created_at + 20.minutes
      allow(conversation).to receive(:updated_at).and_return(resolved_at + 10.minutes)
      event = Events::Base.new('conversation.resolved', resolved_at, conversation: conversation)

      listener.conversation_resolved(event)

      reporting_event = account.reporting_events.where(name: 'conversation_resolved').first
      expect(reporting_event.value).to eq 1200
      expect(reporting_event.event_end_time).to be_within(1.second).of(resolved_at)
    end

    describe 'conversation_bot_resolved' do
      # create an agent bot
      let!(:agent_bot_inbox) { create(:inbox, account: account) }
      let!(:agent_bot) { create(:agent_bot, account: account) }
      let!(:bot_resolved_conversation) { create(:conversation, account: account, inbox: agent_bot_inbox, assignee: user) }

      before do
        create(:agent_bot_inbox, agent_bot: agent_bot, inbox: agent_bot_inbox)
      end

      it 'creates a conversation_bot_resolved event if resolved conversation does not have human interaction' do
        event = Events::Base.new('conversation.resolved', Time.zone.now, conversation: bot_resolved_conversation)
        listener.conversation_resolved(event)
        expect(account.reporting_events.where(name: 'conversation_bot_resolved').count).to be 1
      end

      it 'does not create a conversation_bot_resolved event if resolved conversation inbox does not have active bot' do
        bot_resolved_conversation.update(inbox: inbox)
        event = Events::Base.new('conversation.resolved', Time.zone.now, conversation: bot_resolved_conversation)
        listener.conversation_resolved(event)
        expect(account.reporting_events.where(name: 'conversation_bot_resolved').count).to be 0
      end

      it 'does not create a conversation_bot_resolved event if resolved conversation has human interaction' do
        create(:message, message_type: 'outgoing', account: account, inbox: agent_bot_inbox, conversation: bot_resolved_conversation)
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
      event = Events::Base.new('reply.created', Time.zone.now, waiting_since: 2.hours.ago, message: message)
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
          customer_message_time = 3.hours.ago
          create_customer_message(resolved_conversation, created_at: customer_message_time)

          resolved_conversation.reload
          expect(resolved_conversation.status).to eq('open')

          agent_reply_time = 1.hour.ago
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
          create_customer_message(resolved_conversation, created_at: 5.hours.ago)
          first_agent_reply = create_agent_message(resolved_conversation, created_at: 4.hours.ago)

          event = create_reply_event(first_agent_reply, 5.hours.ago)
          listener.reply_created(event)

          resolved_conversation.update!(status: 'resolved')

          create_customer_message(resolved_conversation, created_at: 2.hours.ago)
          second_agent_reply = create_agent_message(resolved_conversation, created_at: 1.5.hours.ago)

          event = create_reply_event(second_agent_reply, 2.hours.ago)
          listener.reply_created(event)

          events = account.reporting_events.where(name: 'reply_time', conversation_id: resolved_conversation.id)
                          .order(created_at: :asc)
          expect(events.length).to be 2
          expect(events.first.value).to be_within(60).of(3600)
          expect(events.second.value).to be_within(60).of(1800)
        end
      end

      context 'when conversation is manually reopened' do
        it 'sets waiting_since when first customer message arrives after manual reopening' do
          resolved_conversation.update!(status: 'open')

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
      previous_count = account.reporting_events.where(name: 'first_response').count
      event = Events::Base.new('first.reply.created', Time.zone.now, message: message)
      listener.first_reply_created(event)
      expect(account.reporting_events.where(name: 'first_response').count).to eql previous_count + 1
    end

    context 'when business hours enabled for inbox' do
      let(:conversation_created_at) { Time.zone.parse('March 20, 2022 00:00') }
      let(:message_created_at) { Time.zone.parse('March 26, 2022 23:59') }
      let!(:new_inbox) { create(:inbox, working_hours_enabled: true, account: account) }
      let!(:new_conversation) do
        create(:conversation, created_at: conversation_created_at, account: account, inbox: new_inbox, assignee: user)
      end
      let!(:new_message) do
        create(:message, message_type: 'outgoing', created_at: message_created_at,
                         account: account, inbox: new_inbox, conversation: new_conversation)
      end

      it 'creates first_response event with business hour value' do
        event = Events::Base.new('first.reply.created', Time.zone.now, message: new_message)
        listener.first_reply_created(event)
        reporting_event = account.reporting_events.where(name: 'first_response').first
        expect(reporting_event.value_in_business_hours).to be 144_000.0
        expect(reporting_event.user_id).to be new_message.sender_id
      end
    end

    # this ensures last_non_human_activity method accurately accounts for handoff events
    context 'when last handoff event exists' do
      let(:now) { Time.zone.now }
      let(:conversation_updated_at) { now + 20.seconds }
      let(:human_message_created_at) { now + 62.seconds }
      let(:new_conversation) { create(:conversation, account: account, inbox: inbox, assignee: user, updated_at: conversation_updated_at) }
      let(:new_message) do
        create(:message, message_type: 'outgoing', created_at: human_message_created_at, account: account, inbox: inbox,
                         conversation: new_conversation)
      end

      it 'creates first_response event with handoff value' do
        # this will create a handoff event
        event = Events::Base.new('conversation.bot_handoff', conversation_updated_at, conversation: new_conversation)
        listener.conversation_bot_handoff(event)

        # create the first reply event
        event = Events::Base.new('first.reply.created', human_message_created_at, message: new_message)
        listener.first_reply_created(event)
        expect(account.reporting_events.where(name: 'first_response')[0]['value']).to be 42.0
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

      it 'creates conversation_bot_handoff event with business hour value' do
        event = Events::Base.new('conversation.bot_handoff', updated_at, conversation: new_conversation)
        listener.conversation_bot_handoff(event)
        expect(account.reporting_events.where(name: 'conversation_bot_handoff')[0]['value_in_business_hours']).to be 144_000.0
      end
    end

    it 'uses event timestamp even when conversation updated_at changes later' do
      handoff_at = conversation.created_at + 10.minutes
      allow(conversation).to receive(:updated_at).and_return(handoff_at + 15.minutes)
      event = Events::Base.new('conversation.bot_handoff', handoff_at, conversation: conversation)

      listener.conversation_bot_handoff(event)

      reporting_event = account.reporting_events.where(name: 'conversation_bot_handoff').first
      expect(reporting_event.value).to eq 600
      expect(reporting_event.event_end_time).to be_within(1.second).of(handoff_at)
    end
  end

  describe '#conversation_captain_inference_resolved' do
    it 'creates conversation_captain_inference_resolved event' do
      expect(account.reporting_events.where(name: 'conversation_captain_inference_resolved').count).to be 0
      decision_time = conversation.created_at + 60.seconds
      event = Events::Base.new('conversation.captain_inference_resolved', decision_time, conversation: conversation)
      allow(conversation).to receive(:updated_at).and_return(decision_time + 5.minutes)

      listener.conversation_captain_inference_resolved(event)

      reporting_event = account.reporting_events.where(name: 'conversation_captain_inference_resolved').first
      expect(reporting_event).to be_present
      expect(reporting_event.value).to eq 60
      expect(reporting_event.event_end_time).to be_within(1.second).of(decision_time)
    end
  end

  describe '#conversation_captain_inference_handoff' do
    it 'creates conversation_captain_inference_handoff event' do
      expect(account.reporting_events.where(name: 'conversation_captain_inference_handoff').count).to be 0
      decision_time = conversation.created_at + 90.seconds
      event = Events::Base.new('conversation.captain_inference_handoff', decision_time, conversation: conversation)
      allow(conversation).to receive(:updated_at).and_return(decision_time + 5.minutes)

      listener.conversation_captain_inference_handoff(event)

      reporting_event = account.reporting_events.where(name: 'conversation_captain_inference_handoff').first
      expect(reporting_event).to be_present
      expect(reporting_event.value).to eq 90
      expect(reporting_event.event_end_time).to be_within(1.second).of(decision_time)
    end
  end

  describe '#conversation_opened' do
    context 'when conversation is opened for the first time' do
      let(:new_conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }

      it 'creates conversation_opened event with value 0' do
        expect(account.reporting_events.where(name: 'conversation_opened').count).to be 0
        opened_at = Time.zone.now
        event = Events::Base.new('conversation.opened', opened_at, conversation: new_conversation)
        listener.conversation_opened(event)
        expect(account.reporting_events.where(name: 'conversation_opened').count).to be 1

        opened_event = account.reporting_events.where(name: 'conversation_opened').first
        expect(opened_event.value).to eq 0
        expect(opened_event.value_in_business_hours).to eq 0
        expect(opened_event.event_start_time).to be_within(1.second).of(new_conversation.created_at)
        expect(opened_event.event_end_time).to be_within(1.second).of(opened_at)
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

      it 'uses event timestamp even when conversation updated_at changes later' do
        allow(reopened_conversation).to receive(:updated_at).and_return(reopened_time + 20.minutes)
        event = Events::Base.new('conversation.opened', reopened_time, conversation: reopened_conversation)

        listener.conversation_opened(event)

        reopened_event = account.reporting_events.where(name: 'conversation_opened').first
        expect(reopened_event.value).to be_within(1).of(3600)
        expect(reopened_event.event_end_time).to be_within(1.second).of(reopened_time)
      end

      context 'when business hours enabled for inbox' do
        let(:resolved_time) { Time.zone.parse('March 20, 2022 12:00') }
        let(:reopened_time) { Time.zone.parse('March 21, 2022 14:00') }
        let!(:business_hours_inbox) { create(:inbox, working_hours_enabled: true, account: account) }
        let!(:business_hours_conversation) do
          create(:conversation, account: account, inbox: business_hours_inbox, assignee: user, updated_at: reopened_time)
        end

        before do
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

    context 'when latest resolved event is after the conversation opened event timestamp' do
      let(:previous_resolved_time) { Time.zone.parse('March 22, 2022 09:00') }
      let(:future_resolved_time) { Time.zone.parse('March 22, 2022 11:00') }
      let(:reopened_time) { Time.zone.parse('March 22, 2022 10:00') }
      let(:reopened_conversation) do
        create(:conversation, account: account, inbox: inbox, assignee: user, updated_at: reopened_time)
      end

      before do
        create(:reporting_event,
               name: 'conversation_resolved',
               account_id: account.id,
               inbox_id: inbox.id,
               conversation_id: reopened_conversation.id,
               user_id: user.id,
               event_start_time: reopened_conversation.created_at,
               event_end_time: previous_resolved_time)

        create(:reporting_event,
               name: 'conversation_resolved',
               account_id: account.id,
               inbox_id: inbox.id,
               conversation_id: reopened_conversation.id,
               user_id: user.id,
               event_start_time: previous_resolved_time,
               event_end_time: future_resolved_time)
      end

      it 'ignores future resolved events when computing reopen duration' do
        event = Events::Base.new('conversation.opened', reopened_time, conversation: reopened_conversation)
        listener.conversation_opened(event)

        reopened_event = account.reporting_events.where(name: 'conversation_opened').first
        expect(reopened_event.value).to be_within(1).of(3600)
        expect(reopened_event.event_start_time).to be_within(1.second).of(previous_resolved_time)
        expect(reopened_event.event_end_time).to be_within(1.second).of(reopened_time)
      end
    end

    context 'when agent bot resolves and conversation is reopened' do
      # This implicitly tests that the first_response time is correctly calculated
      # By checking that a conversation reopened event is created with the correct values
      let(:agent_bot) { create(:agent_bot, account: account) }
      let(:agent_bot_inbox) { create(:inbox, account: account) }
      let(:bot_resolved_time) { 2.hours.ago }
      let(:reopened_time) { 1.hour.ago }
      let(:bot_conversation) do
        create(:conversation, account: account, inbox: agent_bot_inbox, assignee: user, updated_at: reopened_time)
      end

      before do
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
