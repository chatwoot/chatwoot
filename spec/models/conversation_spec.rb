# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Conversation, type: :model do
  describe '.before_create' do
    let(:conversation) { build(:conversation, display_id: nil) }

    before do
      conversation.save
      conversation.reload
    end

    it 'runs before_create callbacks' do
      expect(conversation.display_id).to eq(1)
    end

    it 'creates a UUID for every conversation automatically' do
      uuid_pattern = /[0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12}$/i
      expect(conversation.uuid).to match(uuid_pattern)
    end
  end

  describe '.after_create' do
    let(:account) { create(:account) }
    let(:agent) { create(:user, email: 'agent1@example.com', account: account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:conversation) do
      create(
        :conversation,
        account: account,
        contact: create(:contact, account: account),
        inbox: inbox,
        assignee: nil
      )
    end

    before do
      allow(Rails.configuration.dispatcher).to receive(:dispatch)
    end

    it 'runs after_create callbacks' do
      # send_events
      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with(described_class::CONVERSATION_CREATED, kind_of(Time), conversation: conversation)
    end
  end

  describe '.after_update' do
    let(:account) { create(:account) }
    let(:conversation) do
      create(:conversation, status: 'open', account: account, assignee: old_assignee)
    end
    let(:old_assignee) do
      create(:user, email: 'agent1@example.com', account: account, role: :agent)
    end
    let(:new_assignee) do
      create(:user, email: 'agent2@example.com', account: account, role: :agent)
    end
    let(:assignment_mailer) { double(deliver: true) }
    let(:label) { create(:label, account: account) }

    before do
      conversation
      new_assignee

      allow(Rails.configuration.dispatcher).to receive(:dispatch)
      Current.user = old_assignee

      conversation.update(
        status: :resolved,
        locked: true,
        contact_last_seen_at: Time.now,
        assignee: new_assignee,
        label_list: [label.title]
      )
    end

    it 'runs after_update callbacks' do
      # notify_status_change
      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with(described_class::CONVERSATION_RESOLVED, kind_of(Time), conversation: conversation)
      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with(described_class::CONVERSATION_READ, kind_of(Time), conversation: conversation)
      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with(described_class::CONVERSATION_LOCK_TOGGLE, kind_of(Time), conversation: conversation)
      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with(described_class::ASSIGNEE_CHANGED, kind_of(Time), conversation: conversation)
    end

    it 'creates conversation activities' do
      # create_activity
      expect(conversation.messages.pluck(:content)).to include("Conversation was marked resolved by #{old_assignee.available_name}")
      expect(conversation.messages.pluck(:content)).to include("Assigned to #{new_assignee.available_name} by #{old_assignee.available_name}")
      expect(conversation.messages.pluck(:content)).to include("#{old_assignee.available_name} added #{label.title}")
    end
  end

  describe '#round robin' do
    let(:account) { create(:account) }
    let(:agent) { create(:user, email: 'agent1@example.com', account: account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:conversation) do
      create(
        :conversation,
        account: account,
        contact: create(:contact, account: account),
        inbox: inbox,
        assignee: nil
      )
    end

    before do
      create(:inbox_member, inbox: inbox, user: agent)
      allow(Redis::Alfred).to receive(:rpoplpush).and_return(agent.id)
    end

    it 'runs round robin on after_save callbacks' do
      # run_round_robin
      expect(conversation.reload.assignee).to eq(agent)
    end

    it 'will not auto assign agent if enable_auto_assignment is false' do
      inbox.update(enable_auto_assignment: false)

      # run_round_robin
      expect(conversation.reload.assignee).to eq(nil)
    end

    it 'will not auto assign agent if its a bot conversation' do
      conversation = create(
        :conversation,
        account: account,
        contact: create(:contact, account: account),
        inbox: inbox,
        status: 'bot',
        assignee: nil
      )

      # run_round_robin
      expect(conversation.reload.assignee).to eq(nil)
    end

    it 'gets triggered on update only when status changes to open' do
      conversation.status = 'resolved'
      conversation.save!
      expect(conversation.reload.assignee).to eq(agent)
      inbox.inbox_members.where(user_id: agent.id).first.destroy!

      # round robin changes assignee in this case since agent doesn't have access to inbox
      agent2 = create(:user, email: 'agent2@example.com', account: account)
      create(:inbox_member, inbox: inbox, user: agent2)
      allow(Redis::Alfred).to receive(:rpoplpush).and_return(agent2.id)
      conversation.status = 'open'
      conversation.save!
      expect(conversation.reload.assignee).to eq(agent2)
    end
  end

  describe '#update_assignee' do
    subject(:update_assignee) { conversation.update_assignee(agent) }

    let(:conversation) { create(:conversation, assignee: nil) }
    let(:agent) do
      create(:user, email: 'agent@example.com', account: conversation.account, role: :agent)
    end
    let(:assignment_mailer) { double(deliver: true) }

    it 'assigns the agent to conversation' do
      expect(update_assignee).to eq(true)
      expect(conversation.reload.assignee).to eq(agent)
    end

    it 'creates a new notification for the agent' do
      expect(update_assignee).to eq(true)
      expect(agent.notifications.count).to eq(1)
    end

    it 'does not create assignment notification if notification setting is turned off' do
      notification_setting = agent.notification_settings.first
      notification_setting.unselect_all_email_flags
      notification_setting.unselect_all_push_flags
      notification_setting.save!

      expect(update_assignee).to eq(true)
      expect(agent.notifications.count).to eq(0)
    end

    context 'when agent is current user' do
      before do
        Current.user = agent
      end

      it 'creates self-assigned message activity' do
        expect(update_assignee).to eq(true)
        expect(conversation.messages.pluck(:content)).to include("#{agent.available_name} self-assigned this conversation")
      end
    end
  end

  describe '#update_labels' do
    let(:account) { create(:account) }
    let(:conversation) { create(:conversation, account: account) }
    let(:agent) do
      create(:user, email: 'agent@example.com', account: account, role: :agent)
    end
    let(:first_label) { create(:label, account: account) }
    let(:second_label) { create(:label, account: account) }
    let(:third_label) { create(:label, account: account) }
    let(:fourth_label) { create(:label, account: account) }

    before do
      conversation
      Current.user = agent

      first_label
      second_label
      third_label
      fourth_label
    end

    it 'adds one label to conversation' do
      labels = [first_label].map(&:title)
      expect(conversation.update_labels(labels)).to eq(true)
      expect(conversation.label_list).to match_array(labels)
      expect(conversation.messages.pluck(:content)).to include("#{agent.available_name} added #{labels.join(', ')}")
    end

    it 'adds and removes previously added labels' do
      labels = [first_label, fourth_label].map(&:title)
      expect(conversation.update_labels(labels)).to eq(true)
      expect(conversation.label_list).to match_array(labels)
      expect(conversation.messages.pluck(:content)).to include("#{agent.available_name} added #{labels.join(', ')}")

      updated_labels = [second_label, third_label].map(&:title)
      expect(conversation.update_labels(updated_labels)).to eq(true)
      expect(conversation.label_list).to match_array(updated_labels)
      expect(conversation.messages.pluck(:content)).to include("#{agent.available_name} added #{updated_labels.join(', ')}")
      expect(conversation.messages.pluck(:content)).to include("#{agent.available_name} removed #{labels.join(', ')}")
    end
  end

  describe '#toggle_status' do
    subject(:toggle_status) { conversation.toggle_status }

    let(:conversation) { create(:conversation, status: :open) }

    it 'toggles conversation status' do
      expect(toggle_status).to eq(true)
      expect(conversation.reload.status).to eq('resolved')
    end
  end

  describe '#lock!' do
    subject(:lock!) { conversation.lock! }

    let(:conversation) { create(:conversation) }

    it 'assigns locks the conversation' do
      expect(lock!).to eq(true)
      expect(conversation.reload.locked).to eq(true)
    end
  end

  describe '#unlock!' do
    subject(:unlock!) { conversation.unlock! }

    let(:conversation) { create(:conversation) }

    it 'unlocks the conversation' do
      expect(unlock!).to eq(true)
      expect(conversation.reload.locked).to eq(false)
    end
  end

  describe '#mute!' do
    subject(:mute!) { conversation.mute! }

    let(:conversation) { create(:conversation) }

    it 'marks conversation as resolved' do
      mute!
      expect(conversation.reload.resolved?).to eq(true)
    end

    it 'marks conversation as muted in redis' do
      mute!
      expect(Redis::Alfred.get(conversation.send(:mute_key))).not_to eq(nil)
    end
  end

  describe '#muted?' do
    subject(:muted?) { conversation.muted? }

    let(:conversation) { create(:conversation) }

    it 'return true if conversation is muted' do
      conversation.mute!
      expect(muted?).to eq(true)
    end

    it 'returns false if conversation is not muted' do
      expect(muted?).to eq(false)
    end
  end

  describe 'unread_messages' do
    subject(:unread_messages) { conversation.unread_messages }

    let(:conversation) { create(:conversation, agent_last_seen_at: 1.hour.ago) }
    let(:message_params) do
      {
        conversation: conversation,
        account: conversation.account,
        inbox: conversation.inbox,
        sender: conversation.assignee
      }
    end
    let!(:message) do
      create(:message, created_at: 1.minute.ago, **message_params)
    end

    before do
      create(:message, created_at: 1.month.ago, **message_params)
    end

    it 'returns unread messages' do
      expect(unread_messages).to include(message)
    end
  end

  describe 'unread_incoming_messages' do
    subject(:unread_incoming_messages) { conversation.unread_incoming_messages }

    let(:conversation) { create(:conversation, agent_last_seen_at: 1.hour.ago) }
    let(:message_params) do
      {
        conversation: conversation,
        account: conversation.account,
        inbox: conversation.inbox,
        sender: conversation.assignee,
        created_at: 1.minute.ago
      }
    end
    let!(:message) do
      create(:message, message_type: :incoming, **message_params)
    end

    before do
      create(:message, message_type: :outgoing, **message_params)
    end

    it 'returns unread incoming messages' do
      expect(unread_incoming_messages).to contain_exactly(message)
    end
  end

  describe '#push_event_data' do
    subject(:push_event_data) { conversation.push_event_data }

    let(:conversation) { create(:conversation) }
    let(:expected_data) do
      {
        additional_attributes: nil,
        meta: {
          sender: conversation.contact.push_event_data,
          assignee: conversation.assignee
        },
        id: conversation.display_id,
        messages: [],
        inbox_id: conversation.inbox_id,
        status: conversation.status,
        timestamp: conversation.last_activity_at.to_i,
        can_reply: true,
        channel: 'Channel::WebWidget',
        contact_last_seen_at: conversation.contact_last_seen_at.to_i,
        agent_last_seen_at: conversation.agent_last_seen_at.to_i,
        unread_count: 0
      }
    end

    it 'returns push event payload' do
      expect(push_event_data).to eq(expected_data)
    end
  end

  describe '#lock_event_data' do
    subject(:lock_event_data) { conversation.lock_event_data }

    let(:conversation) do
      build(:conversation, display_id: 505, locked: false)
    end

    it 'returns lock event payload' do
      expect(lock_event_data).to eq(id: 505, locked: false)
    end
  end

  describe '#botinbox: when conversation created inside inbox with agent bot' do
    let!(:bot_inbox) { create(:agent_bot_inbox) }
    let(:conversation) { create(:conversation, inbox: bot_inbox.inbox) }

    it 'returns conversation status as bot' do
      expect(conversation.status).to eq('bot')
    end
  end

  describe '#can_reply?' do
    describe 'on channels without 24 hour restriction' do
      let(:conversation) { create(:conversation) }

      it 'returns true' do
        expect(conversation.can_reply?).to eq true
      end
    end

    describe 'on channels with 24 hour restriction' do
      let!(:facebook_channel) { create(:channel_facebook_page) }
      let!(:facebook_inbox) { create(:inbox, channel: facebook_channel, account: facebook_channel.account) }
      let!(:conversation) { create(:conversation, inbox: facebook_inbox, account: facebook_channel.account) }

      it 'returns false if there are no incoming messages' do
        expect(conversation.can_reply?).to eq false
      end

      it 'return false if last incoming message is outside of 24 hour window' do
        create(
          :message,
          account: conversation.account,
          inbox: facebook_inbox,
          conversation: conversation,
          created_at: Time.now - 25.hours
        )
        expect(conversation.can_reply?).to eq false
      end

      it 'return true if last incoming message is inside 24 hour window' do
        create(
          :message,
          account: conversation.account,
          inbox: facebook_inbox,
          conversation: conversation
        )
        expect(conversation.can_reply?).to eq true
      end
    end
  end
end
