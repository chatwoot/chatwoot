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
        expect(account.reporting_events.where(name: 'first_response')[0]['value_in_business_hours']).to be 144_000.0
      end
    end
  end
end
