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

    context 'when business hours enabled for inbox' do
      let(:created_at) { Time.zone.parse('March 20, 2022 00:00') }
      let(:updated_at) { Time.zone.parse('March 26, 2022 23:59') }
      let!(:new_inbox) { create(:inbox, working_hours_enabled: true, account: account) }
      let!(:new_conversation) do
        create(:conversation, created_at: created_at, updated_at: updated_at, account: account, inbox: new_inbox, assignee: user)
      end

      it 'creates conversation_resolved event with business hour value' do
        event = Events::Base.new('conversation.resolved', Time.zone.now, conversation: new_conversation)
        listener.conversation_resolved(event)
        expect(account.reporting_events.where(name: 'conversation_resolved')[0]['value_in_business_hours']).to be 144_000.0
      end
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
        bot_resolved_conversation.update!(inbox: inbox)
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
    it 'creates reply created event' do
      event = Events::Base.new('reply.created', Time.zone.now, waiting_since: 2.hours.ago, message: message)
      listener.reply_created(event)

      events = account.reporting_events.where(name: 'reply_time', conversation_id: message.conversation_id)
      expect(events.length).to be 1
      expect(events.first.value).to be_within(1).of(7200)
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
        event = Events::Base.new('conversation.bot_handoff', Time.zone.now, conversation: new_conversation)
        listener.conversation_bot_handoff(event)
        expect(account.reporting_events.where(name: 'conversation_bot_handoff')[0]['value_in_business_hours']).to be 144_000.0
      end
    end
  end
end
