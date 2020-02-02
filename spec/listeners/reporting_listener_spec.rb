require 'rails_helper'
describe ReportingListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let(:report_identity) { Reports::UpdateAccountIdentity.new(account, Time.zone.now) }
  let!(:user) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }

  describe '#message_created' do
    let(:event_name) { :'conversation.created' }

    context 'when user activity message' do
      it 'does not increment messages count' do
        activity_message = create(:message, message_type: 'activity', account: account, inbox: inbox, conversation: conversation)
        event = Events::Base.new(event_name, Time.zone.now, message: activity_message)

        allow(Reports::UpdateAccountIdentity).to receive(:new).and_return(report_identity)
        allow(report_identity).to receive(:incr_outgoing_messages_count).exactly(0).times
        allow(report_identity).to receive(:incr_incoming_messages_count).exactly(0).times

        listener.message_created(event)
      end
    end

    context 'when user conversation message' do
      it 'increments messages count' do
        conversation_message = create(:message, message_type: 'outgoing', account: account, inbox: inbox, conversation: conversation)
        event = Events::Base.new(event_name, Time.zone.now, message: conversation_message)

        allow(Reports::UpdateAccountIdentity).to receive(:new).and_return(report_identity)
        allow(report_identity).to receive(:incr_outgoing_messages_count).once
        allow(report_identity).to receive(:incr_incoming_messages_count).exactly(0).times

        listener.message_created(event)
      end
    end
  end
end
