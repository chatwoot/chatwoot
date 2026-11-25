require 'rails_helper'

describe InternalChatListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let!(:admin) { create(:user, account: account, role: :administrator) }
  let!(:agent) { create(:user, account: account, role: :agent) }
  let!(:other_agent) { create(:user, account: account, role: :agent) }

  before do
    Current.user = nil
    Current.account = nil
  end

  describe '#internal_chat_message_created' do
    context 'when channel is public' do
      let!(:channel) { create(:internal_chat_channel, :public_channel, account: account) }
      let!(:message) { create(:internal_chat_message, account: account, channel: channel, sender: agent) }
      let!(:event) { Events::Base.new(:'internal_chat.message.created', Time.zone.now, message: message) }

      it 'broadcasts to all account users including the sender' do
        allow(ActionCableBroadcastJob).to receive(:perform_later)
        listener.internal_chat_message_created(event)
        expect(ActionCableBroadcastJob).to have_received(:perform_later).with(
          a_collection_containing_exactly(agent.pubsub_token, admin.pubsub_token, other_agent.pubsub_token),
          'internal_chat.message.created',
          hash_including(
            id: message.id,
            content: message.content,
            internal_chat_channel_id: channel.id,
            account_id: account.id
          )
        )
      end
    end

    context 'when channel is private' do
      let!(:channel) { create(:internal_chat_channel, :private_channel, account: account) }
      let!(:message) { create(:internal_chat_message, account: account, channel: channel, sender: agent) }
      let!(:event) { Events::Base.new(:'internal_chat.message.created', Time.zone.now, message: message) }

      before do
        create(:internal_chat_channel_member, channel: channel, user: agent)
        create(:internal_chat_channel_member, channel: channel, user: admin)
      end

      it 'broadcasts to all channel members including the sender' do
        allow(ActionCableBroadcastJob).to receive(:perform_later)
        listener.internal_chat_message_created(event)
        expect(ActionCableBroadcastJob).to have_received(:perform_later).with(
          a_collection_containing_exactly(agent.pubsub_token, admin.pubsub_token),
          'internal_chat.message.created',
          hash_including(
            id: message.id,
            content: message.content,
            account_id: account.id
          )
        )
      end

      it 'does not broadcast to non-members' do
        allow(ActionCableBroadcastJob).to receive(:perform_later)
        listener.internal_chat_message_created(event)
        expect(ActionCableBroadcastJob).to have_received(:perform_later).with(
          satisfy { |tokens| tokens.exclude?(other_agent.pubsub_token) },
          'internal_chat.message.created',
          anything
        )
      end
    end
  end

  describe '#internal_chat_typing_on' do
    let!(:channel) { create(:internal_chat_channel, :public_channel, account: account) }
    let!(:event) { Events::Base.new(:'internal_chat.typing_on', Time.zone.now, channel: channel, user: agent) }

    it 'broadcasts to all account users except the typing user' do
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        a_collection_containing_exactly(admin.pubsub_token, other_agent.pubsub_token),
        'internal_chat.typing_on',
        hash_including(
          channel: { id: channel.id },
          user: agent.push_event_data,
          account_id: account.id
        )
      )
      listener.internal_chat_typing_on(event)
    end
  end

  describe '#internal_chat_typing_off' do
    let!(:channel) { create(:internal_chat_channel, :public_channel, account: account) }
    let!(:event) { Events::Base.new(:'internal_chat.typing_off', Time.zone.now, channel: channel, user: agent) }

    it 'broadcasts to all account users except the typing user' do
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        a_collection_containing_exactly(admin.pubsub_token, other_agent.pubsub_token),
        'internal_chat.typing_off',
        hash_including(
          channel: { id: channel.id },
          user: agent.push_event_data,
          account_id: account.id
        )
      )
      listener.internal_chat_typing_off(event)
    end
  end

  describe '#internal_chat_reaction_created' do
    let!(:channel) { create(:internal_chat_channel, :public_channel, account: account) }
    let!(:message) { create(:internal_chat_message, account: account, channel: channel, sender: agent) }
    let!(:reaction) { create(:internal_chat_reaction, message: message, user: other_agent) }
    let!(:event) { Events::Base.new(:'internal_chat.reaction.created', Time.zone.now, reaction: reaction) }

    it 'broadcasts to all channel members including the reaction creator' do
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        a_collection_containing_exactly(admin.pubsub_token, agent.pubsub_token, other_agent.pubsub_token),
        'internal_chat.reaction.created',
        hash_including(
          id: reaction.id,
          emoji: reaction.emoji,
          message_id: message.id,
          account_id: account.id
        )
      )
      listener.internal_chat_reaction_created(event)
    end
  end

  describe '#internal_chat_message_updated' do
    let!(:channel) { create(:internal_chat_channel, :public_channel, account: account) }
    let!(:message) { create(:internal_chat_message, account: account, channel: channel, sender: agent) }
    let!(:event) { Events::Base.new(:'internal_chat.message.updated', Time.zone.now, message: message) }

    it 'broadcasts to all channel members including the sender' do
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        a_collection_containing_exactly(admin.pubsub_token, agent.pubsub_token, other_agent.pubsub_token),
        'internal_chat.message.updated',
        hash_including(
          id: message.id,
          content: message.content,
          account_id: account.id
        )
      )
      listener.internal_chat_message_updated(event)
    end
  end

  describe '#internal_chat_message_deleted' do
    let!(:channel) { create(:internal_chat_channel, :public_channel, account: account) }
    let(:message_data) { { account_id: account.id, internal_chat_channel_id: channel.id, id: 999 } }
    let!(:event) { Events::Base.new(:'internal_chat.message.deleted', Time.zone.now, message_data: message_data) }

    it 'broadcasts to all channel members' do
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        a_collection_containing_exactly(admin.pubsub_token, agent.pubsub_token, other_agent.pubsub_token),
        'internal_chat.message.deleted',
        hash_including(
          account_id: account.id,
          internal_chat_channel_id: channel.id
        )
      )
      listener.internal_chat_message_deleted(event)
    end

    context 'when account or channel is not found' do
      let(:message_data) { { account_id: 0, internal_chat_channel_id: 0, id: 999 } }

      it 'does not broadcast' do
        expect(ActionCableBroadcastJob).not_to receive(:perform_later)
        listener.internal_chat_message_deleted(event)
      end
    end

    context 'when account and channel belong to different accounts' do
      let(:other_account) { create(:account) }
      let(:other_channel) { create(:internal_chat_channel, :public_channel, account: other_account) }
      let(:message_data) { { account_id: account.id, internal_chat_channel_id: other_channel.id, id: 999 } }

      it 'does not broadcast' do
        expect(ActionCableBroadcastJob).not_to receive(:perform_later)
        listener.internal_chat_message_deleted(event)
      end
    end
  end

  describe '#internal_chat_reaction_deleted' do
    let!(:channel) { create(:internal_chat_channel, :public_channel, account: account) }
    let(:reaction_data) { { account_id: account.id, internal_chat_channel_id: channel.id, id: 999 } }
    let!(:event) { Events::Base.new(:'internal_chat.reaction.deleted', Time.zone.now, reaction_data: reaction_data) }

    it 'broadcasts to all channel members' do
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        a_collection_containing_exactly(admin.pubsub_token, agent.pubsub_token, other_agent.pubsub_token),
        'internal_chat.reaction.deleted',
        hash_including(
          account_id: account.id,
          internal_chat_channel_id: channel.id
        )
      )
      listener.internal_chat_reaction_deleted(event)
    end

    context 'when account or channel is not found' do
      let(:reaction_data) { { account_id: 0, internal_chat_channel_id: 0, id: 999 } }

      it 'does not broadcast' do
        expect(ActionCableBroadcastJob).not_to receive(:perform_later)
        listener.internal_chat_reaction_deleted(event)
      end
    end

    context 'when account and channel belong to different accounts' do
      let(:other_account) { create(:account) }
      let(:other_channel) { create(:internal_chat_channel, :public_channel, account: other_account) }
      let(:reaction_data) { { account_id: account.id, internal_chat_channel_id: other_channel.id, id: 999 } }

      it 'does not broadcast' do
        expect(ActionCableBroadcastJob).not_to receive(:perform_later)
        listener.internal_chat_reaction_deleted(event)
      end
    end
  end

  describe 'recipients' do
    let!(:channel) { create(:internal_chat_channel, :private_channel, account: account) }
    let!(:message) { create(:internal_chat_message, account: account, channel: channel, sender: admin) }
    let(:event) { Events::Base.new(:'internal_chat.message.created', Time.zone.now, message: message) }

    before do
      create(:internal_chat_channel_member, channel: channel, user: admin)
      create(:internal_chat_channel_member, channel: channel, user: agent)
      allow(ActionCableBroadcastJob).to receive(:perform_later)
    end

    it 'leaves out members without internal_chat.access' do
      stub_const('FeatureAccess::CAPABILITIES', { 'internal_chat.access' => { agent_default: false } })

      listener.internal_chat_message_created(event)

      expect(ActionCableBroadcastJob).to have_received(:perform_later)
        .with([admin.pubsub_token], 'internal_chat.message.created', anything)
    end

    it 'leaves out a member who is no longer in the account' do
      account.account_users.find_by(user: agent).destroy!

      listener.internal_chat_message_created(event)

      expect(ActionCableBroadcastJob).to have_received(:perform_later)
        .with([admin.pubsub_token], 'internal_chat.message.created', anything)
    end

    it 'filters the token list a controller captured before destroying the channel' do
      stub_const('FeatureAccess::CAPABILITIES', { 'internal_chat.access' => { agent_default: false } })
      captured = Events::Base.new(:'internal_chat.channel.updated', Time.zone.now,
                                  channel: channel, member_tokens: [admin.pubsub_token, agent.pubsub_token])

      listener.internal_chat_channel_updated(captured)

      expect(ActionCableBroadcastJob).to have_received(:perform_later)
        .with([admin.pubsub_token], 'internal_chat.channel.updated', anything)
    end
  end
end
