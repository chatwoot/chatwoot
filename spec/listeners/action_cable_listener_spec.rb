require 'rails_helper'
describe ActionCableListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let!(:admin) { create(:user, account: account, role: :administrator) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:agent) { create(:user, account: account, role: :agent) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: agent) }
  let!(:message) do
    create(:message, message_type: 'outgoing',
                     account: account, inbox: inbox, conversation: conversation)
  end
  let!(:event) { Events::Base.new(event_name, Time.zone.now, message: message) }

  before do
    create(:inbox_member, inbox: inbox, user: agent)
  end

  describe '#message_created' do
    let(:event_name) { :'message.created' }

    it 'sends message to account admins, inbox agents and the contact' do
      expect(ActionCableBroadcastJob).to receive(:perform_later).with([admin.pubsub_token], 'message.created', message.push_event_data)
      expect(ActionCableBroadcastJob).to receive(:perform_later).with([agent.pubsub_token], 'message.created', message.push_event_data)
      expect(ActionCableBroadcastJob).to receive(:perform_later).with([conversation.contact.pubsub_token], 'message.created', message.push_event_data)
      listener.message_created(event)
    end
  end
end
