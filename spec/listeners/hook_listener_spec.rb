require 'rails_helper'
describe HookListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }
  let!(:message) do
    create(:message, message_type: 'outgoing',
                     account: account, inbox: inbox, conversation: conversation)
  end
  let!(:event) { Events::Base.new(event_name, Time.zone.now, message: message) }

  describe '#message_created' do
    let(:event_name) { :'conversation.created' }

    context 'when hook is not configured' do
      it 'does not trigger hook job' do
        expect(HookJob).to receive(:perform_later).exactly(0).times
        listener.message_created(event)
      end
    end

    context 'when hook is configured' do
      it 'triggers hook job' do
        hook = create(:integrations_hook, account: account)
        expect(HookJob).to receive(:perform_later).with(hook, message).once
        listener.message_created(event)
      end
    end
  end
end
