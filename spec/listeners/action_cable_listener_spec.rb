require 'rails_helper'
describe ActionCableListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let!(:admin) { create(:user, account: account, role: :administrator) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:agent) { create(:user, account: account, role: :agent) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: agent) }

  before do
    create(:inbox_member, inbox: inbox, user: agent)
    Current.user = nil
    Current.account = nil
  end

  describe '#message_created' do
    let(:event_name) { :'message.created' }
    let!(:message) do
      create(:message, message_type: 'outgoing',
                       account: account, inbox: inbox, conversation: conversation)
    end
    let!(:event) { Events::Base.new(event_name, Time.zone.now, message: message) }

    it 'sends message to account admins, inbox agents and the contact' do
      # HACK: to reload conversation inbox members
      expect(conversation.inbox.reload.inbox_members.count).to eq(1)

      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        a_collection_containing_exactly(
          agent.pubsub_token, admin.pubsub_token, conversation.contact_inbox.pubsub_token
        ),
        'message.created',
        message.push_event_data.merge(account_id: account.id),
        nil
      )
      listener.message_created(event)
    end

    it 'sends message to all hmac verified contact inboxes' do
      # HACK: to reload conversation inbox members
      expect(conversation.inbox.reload.inbox_members.count).to eq(1)
      conversation.contact_inbox.update(hmac_verified: true)
      # creating a non verified contact inbox to ensure the events are not sent to it
      create(:contact_inbox, contact: conversation.contact, inbox: inbox)
      verified_contact_inbox = create(:contact_inbox, contact: conversation.contact, inbox: inbox, hmac_verified: true)

      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        a_collection_containing_exactly(
          agent.pubsub_token, admin.pubsub_token, conversation.contact_inbox.pubsub_token, verified_contact_inbox.pubsub_token
        ),
        'message.created',
        message.push_event_data.merge(account_id: account.id),
        nil
      )
      listener.message_created(event)
    end
  end

  describe '#typing_on' do
    let(:event_name) { :'conversation.typing_on' }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation, user: agent, is_private: false) }

    it 'sends message to account admins, inbox agents and the contact' do
      # HACK: to reload conversation inbox members
      expect(conversation.inbox.reload.inbox_members.count).to eq(1)
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        a_collection_containing_exactly(
          admin.pubsub_token, conversation.contact_inbox.pubsub_token
        ),
        'conversation.typing_on', { conversation: conversation.push_event_data,
                                    user: agent.push_event_data,
                                    account_id: account.id,
                                    is_private: false },
        nil
      )
      listener.conversation_typing_on(event)
    end
  end

  describe '#typing_on with contact' do
    let(:event_name) { :'conversation.typing_on' }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation, user: conversation.contact, is_private: false) }

    it 'sends message to account admins, inbox agents and the contact' do
      # HACK: to reload conversation inbox members
      expect(conversation.inbox.reload.inbox_members.count).to eq(1)
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        a_collection_containing_exactly(
          admin.pubsub_token, agent.pubsub_token
        ),
        'conversation.typing_on', { conversation: conversation.push_event_data,
                                    user: conversation.contact.push_event_data,
                                    account_id: account.id,
                                    is_private: false },
        nil
      )
      listener.conversation_typing_on(event)
    end
  end

  describe '#typing_off' do
    let(:event_name) { :'conversation.typing_off' }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation, user: agent, is_private: false) }

    it 'sends message to account admins, inbox agents and the contact' do
      # HACK: to reload conversation inbox members
      expect(conversation.inbox.reload.inbox_members.count).to eq(1)
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        a_collection_containing_exactly(
          admin.pubsub_token, conversation.contact_inbox.pubsub_token
        ),
        'conversation.typing_off', { conversation: conversation.push_event_data,
                                     user: agent.push_event_data,
                                     account_id: account.id,
                                     is_private: false },
        nil
      )
      listener.conversation_typing_off(event)
    end
  end

  describe '#contact_deleted' do
    let(:event_name) { :'contact.deleted' }
    let!(:contact) { create(:contact, account: account) }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, contact: contact) }

    it 'sends message to account admins, inbox agents' do
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        a_collection_containing_exactly(
          agent.pubsub_token, admin.pubsub_token
        ),
        'contact.deleted',
        contact.push_event_data.merge(account_id: account.id),
        nil
      )
      listener.contact_deleted(event)
    end
  end

  describe '#notification_deleted' do
    let(:event_name) { :'notification.deleted' }
    let!(:notification) { create(:notification, account: account, user: agent) }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, notification: notification) }

    it 'sends message to account admins, inbox agents' do
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        [agent.pubsub_token],
        'notification.deleted',
        {
          account_id: notification.account_id,
          notification: {
            id: notification.id
          },
          unread_count: 1,
          count: 1
        },
        nil
      )

      listener.notification_deleted(event)
    end
  end

  describe '#notification_updated' do
    let(:event_name) { :'notification.updated' }
    let!(:notification) { create(:notification, account: account, user: agent) }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, notification: notification) }

    it 'sends notification to account admins, inbox agents' do
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        [agent.pubsub_token],
        'notification.updated',
        {
          account_id: notification.account_id,
          notification: notification.push_event_data,
          unread_count: 1,
          count: 1
        },
        nil
      )

      listener.notification_updated(event)
    end
  end

  describe '#conversation_updated' do
    let(:event_name) { :'conversation.updated' }
    let(:timestamp) { Time.zone.now }
    let!(:event) { Events::Base.new(event_name, timestamp, conversation: conversation, user: agent, is_private: false) }

    before do
      conversation.add_labels(['support'])
    end

    it 'sends update to inbox members' do
      expect(conversation.inbox.reload.inbox_members.count).to eq(1)

      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        [agent.pubsub_token, admin.pubsub_token, conversation.contact_inbox.pubsub_token],
        'conversation.updated',
        conversation.push_event_data.merge(account_id: account.id),
        timestamp.to_f
      )
      listener.conversation_updated(event)
    end

    it 'broadcast event with label data' do
      expect(conversation.reload.push_event_data[:labels]).to eq(conversation.labels.pluck(:name))

      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        [agent.pubsub_token, admin.pubsub_token, conversation.contact_inbox.pubsub_token],
        'conversation.updated',
        conversation.push_event_data.merge(account_id: account.id),
        timestamp.to_f
      )
      listener.conversation_updated(event)
    end
  end

  context 'with event timestamps' do
    let(:timestamp) { Time.zone.now }

    describe '#conversation_created' do
      let(:event_name) { :'conversation.created' }
      let!(:event) { Events::Base.new(event_name, timestamp, conversation: conversation) }

      it 'sends event with timestamp' do
        expect(ActionCableBroadcastJob).to receive(:perform_later).with(
          [agent.pubsub_token, admin.pubsub_token, conversation.contact_inbox.pubsub_token],
          'conversation.created',
          conversation.push_event_data.merge(account_id: account.id),
          timestamp.to_f
        )
        listener.conversation_created(event)
      end
    end

    describe '#conversation_status_changed' do
      let(:event_name) { :'conversation.status_changed' }
      let!(:event) { Events::Base.new(event_name, timestamp, conversation: conversation) }

      it 'sends event with timestamp' do
        expect(ActionCableBroadcastJob).to receive(:perform_later).with(
          [agent.pubsub_token, admin.pubsub_token, conversation.contact_inbox.pubsub_token],
          'conversation.status_changed',
          conversation.push_event_data.merge(account_id: account.id),
          timestamp.to_f
        )
        listener.conversation_status_changed(event)
      end
    end

    describe '#assignee_changed' do
      let(:event_name) { :'conversation.assignee_changed' }
      let!(:event) { Events::Base.new(event_name, timestamp, conversation: conversation) }

      it 'sends event with timestamp' do
        expect(ActionCableBroadcastJob).to receive(:perform_later).with(
          [agent.pubsub_token, admin.pubsub_token],
          'assignee.changed',
          conversation.push_event_data.merge(account_id: account.id),
          timestamp.to_f
        )
        listener.assignee_changed(event)
      end
    end

    describe '#team_changed' do
      let(:event_name) { :'conversation.team_changed' }
      let!(:event) { Events::Base.new(event_name, timestamp, conversation: conversation) }

      it 'sends event with timestamp' do
        expect(ActionCableBroadcastJob).to receive(:perform_later).with(
          [agent.pubsub_token, admin.pubsub_token],
          'team.changed',
          conversation.push_event_data.merge(account_id: account.id),
          timestamp.to_f
        )
        listener.team_changed(event)
      end
    end

    # Update the existing conversation_updated test to include timestamp verification
    describe '#conversation_updated' do
      let(:event_name) { :'conversation.updated' }
      let!(:event) { Events::Base.new(event_name, timestamp, conversation: conversation, user: agent, is_private: false) }

      before do
        conversation.add_labels(['support'])
      end

      it 'sends update to inbox members with timestamp' do
        expect(conversation.inbox.reload.inbox_members.count).to eq(1)

        expect(ActionCableBroadcastJob).to receive(:perform_later).with(
          [agent.pubsub_token, admin.pubsub_token, conversation.contact_inbox.pubsub_token],
          'conversation.updated',
          conversation.push_event_data.merge(account_id: account.id),
          timestamp.to_f
        )
        listener.conversation_updated(event)
      end
    end
  end
end
