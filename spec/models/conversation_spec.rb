# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join 'spec/models/concerns/assignment_handler_shared.rb'
require Rails.root.join 'spec/models/concerns/auto_assignment_handler_shared.rb'

RSpec.describe Conversation, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:inbox) }
  end

  describe 'concerns' do
    it_behaves_like 'assignment_handler'
    it_behaves_like 'auto_assignment_handler'
  end

  describe '.before_create' do
    let(:conversation) { build(:conversation, display_id: nil) }

    before do
      conversation.save!
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
        .with(described_class::CONVERSATION_CREATED, kind_of(Time), conversation: conversation, notifiable_assignee_change: false,
                                                                    changed_attributes: nil, performed_by: nil)
    end
  end

  describe '.validate jsonb attributes' do
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

    it 'validate length of additional_attributes value' do
      conversation.additional_attributes = { company_name: 'some_company' * 200, contact_number: 19_999_999_999 }
      conversation.valid?
      error_messages = conversation.errors.messages
      expect(error_messages[:additional_attributes][0]).to eq('company_name length should be < 1500')
      expect(error_messages[:additional_attributes][1]).to eq('contact_number value should be < 9999999999')
    end

    it 'validate length of custom_attributes value' do
      conversation.custom_attributes = { company_name: 'some_company' * 200, contact_number: 19_999_999_999 }
      conversation.valid?
      error_messages = conversation.errors.messages
      expect(error_messages[:custom_attributes][0]).to eq('company_name length should be < 1500')
      expect(error_messages[:custom_attributes][1]).to eq('contact_number value should be < 9999999999')
    end
  end

  describe '.after_update' do
    let!(:account) { create(:account) }
    let!(:old_assignee) do
      create(:user, email: 'agent1@example.com', account: account, role: :agent)
    end
    let(:new_assignee) do
      create(:user, email: 'agent2@example.com', account: account, role: :agent)
    end
    let!(:conversation) do
      create(:conversation, status: 'open', account: account, assignee: old_assignee)
    end
    let(:assignment_mailer) { double(deliver: true) }
    let(:label) { create(:label, account: account) }

    before do
      allow(Rails.configuration.dispatcher).to receive(:dispatch)
      Current.user = old_assignee
    end

    it 'sends conversation updated event if labels are updated' do
      conversation.update(label_list: [label.title])
      changed_attributes = conversation.previous_changes
      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with(
          described_class::CONVERSATION_UPDATED,
          kind_of(Time),
          conversation: conversation,
          notifiable_assignee_change: false,
          changed_attributes: changed_attributes,
          performed_by: nil
        ).exactly(2).times
    end

    it 'runs after_update callbacks' do
      conversation.update(
        status: :resolved,
        contact_last_seen_at: Time.now,
        assignee: new_assignee
      )
      status_change = conversation.status_change
      changed_attributes = conversation.previous_changes

      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with(described_class::CONVERSATION_RESOLVED, kind_of(Time), conversation: conversation, notifiable_assignee_change: true,
                                                                     changed_attributes: status_change, performed_by: nil)
      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with(described_class::CONVERSATION_READ, kind_of(Time), conversation: conversation, notifiable_assignee_change: true,
                                                                 changed_attributes: nil, performed_by: nil)
      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with(described_class::ASSIGNEE_CHANGED, kind_of(Time), conversation: conversation, notifiable_assignee_change: true,
                                                                changed_attributes: nil, performed_by: nil)
      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with(described_class::CONVERSATION_UPDATED, kind_of(Time), conversation: conversation, notifiable_assignee_change: true,
                                                                    changed_attributes: changed_attributes, performed_by: nil)
    end

    it 'will not run conversation_updated event for empty updates' do
      conversation.save!
      expect(Rails.configuration.dispatcher).not_to have_received(:dispatch)
        .with(described_class::CONVERSATION_UPDATED, kind_of(Time), conversation: conversation, notifiable_assignee_change: true)
    end

    it 'will not run conversation_updated event for non whitelisted keys' do
      conversation.update(updated_at: DateTime.now.utc)
      expect(Rails.configuration.dispatcher).not_to have_received(:dispatch)
        .with(described_class::CONVERSATION_UPDATED, kind_of(Time), conversation: conversation, notifiable_assignee_change: true)
    end

    it 'creates conversation activities' do
      conversation.update(
        status: :resolved,
        contact_last_seen_at: Time.now,
        assignee: new_assignee,
        label_list: [label.title]
      )

      expect(Conversations::ActivityMessageJob)
        .to(have_been_enqueued.at_least(:once)
        .with(conversation, { account_id: conversation.account_id, inbox_id: conversation.inbox_id, message_type: :activity,
                              content: "#{old_assignee.name} added #{label.title}" }))
      expect(Conversations::ActivityMessageJob)
        .to(have_been_enqueued.at_least(:once)
        .with(conversation, { account_id: conversation.account_id, inbox_id: conversation.inbox_id, message_type: :activity,
                              content: "Conversation was marked resolved by #{old_assignee.name}" }))
      expect(Conversations::ActivityMessageJob)
        .to(have_been_enqueued.at_least(:once)
        .with(conversation, { account_id: conversation.account_id, inbox_id: conversation.inbox_id, message_type: :activity,
                              content: "Assigned to #{new_assignee.name} by #{old_assignee.name}" }))
    end

    it 'adds a message for system auto resolution if marked resolved by system' do
      account.update(auto_resolve_duration: 40)
      conversation2 = create(:conversation, status: 'open', account: account, assignee: old_assignee)
      Current.user = nil

      system_resolved_message = "Conversation was marked resolved by system due to #{account.auto_resolve_duration} days of inactivity"
      expect { conversation2.update(status: :resolved) }
        .to have_enqueued_job(Conversations::ActivityMessageJob)
        .with(conversation2, { account_id: conversation2.account_id, inbox_id: conversation2.inbox_id, message_type: :activity,
                               content: system_resolved_message })
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

      expect { conversation.update_labels(labels) }
        .to have_enqueued_job(Conversations::ActivityMessageJob)
        .with(conversation, { account_id: conversation.account_id, inbox_id: conversation.inbox_id, message_type: :activity,
                              content: "#{agent.name} added #{labels.join(', ')}"  })

      expect(conversation.label_list).to match_array(labels)
    end

    it 'adds and removes previously added labels' do
      labels = [first_label, fourth_label].map(&:title)
      expect { conversation.update_labels(labels) }
        .to have_enqueued_job(Conversations::ActivityMessageJob)
        .with(conversation, { account_id: conversation.account_id, inbox_id: conversation.inbox_id, message_type: :activity,
                              content: "#{agent.name} added #{labels.join(', ')}"  })
      expect(conversation.label_list).to match_array(labels)

      updated_labels = [second_label, third_label].map(&:title)
      expect(conversation.update_labels(updated_labels)).to be(true)
      expect(conversation.label_list).to match_array(updated_labels)

      expect(Conversations::ActivityMessageJob)
        .to(have_been_enqueued.at_least(:once)
        .with(conversation, { account_id: conversation.account_id, inbox_id: conversation.inbox_id,
                              message_type: :activity, content: "#{agent.name} added #{updated_labels.join(', ')}" }))
      expect(Conversations::ActivityMessageJob)
        .to(have_been_enqueued.at_least(:once)
        .with(conversation, { account_id: conversation.account_id, inbox_id: conversation.inbox_id,
                              message_type: :activity, content: "#{agent.name} removed #{labels.join(', ')}" }))
    end
  end

  describe '#toggle_status' do
    it 'toggles conversation status to resolved when open' do
      conversation = create(:conversation, status: 'open')
      expect(conversation.toggle_status).to be(true)
      expect(conversation.reload.status).to eq('resolved')
    end

    it 'toggles conversation status to open when resolved' do
      conversation = create(:conversation, status: 'resolved')
      expect(conversation.toggle_status).to be(true)
      expect(conversation.reload.status).to eq('open')
    end

    it 'toggles conversation status to open when pending' do
      conversation = create(:conversation, status: 'pending')
      expect(conversation.toggle_status).to be(true)
      expect(conversation.reload.status).to eq('open')
    end

    it 'toggles conversation status to open when snoozed' do
      conversation = create(:conversation, status: 'snoozed')
      expect(conversation.toggle_status).to be(true)
      expect(conversation.reload.status).to eq('open')
    end
  end

  describe '#ensure_snooze_until_reset' do
    it 'resets the snoozed_until when status is toggled' do
      conversation = create(:conversation, status: 'snoozed', snoozed_until: 2.days.from_now)
      expect(conversation.snoozed_until).not_to be_nil
      expect(conversation.toggle_status).to be(true)
      expect(conversation.reload.snoozed_until).to be_nil
    end
  end

  describe '#mute!' do
    subject(:mute!) { conversation.mute! }

    let(:user) do
      create(:user, email: 'agent2@example.com', account: create(:account), role: :agent)
    end

    let(:conversation) { create(:conversation) }

    before { Current.user = user }

    it 'marks conversation as resolved' do
      mute!
      expect(conversation.reload.resolved?).to be(true)
    end

    it 'marks conversation as muted in redis' do
      mute!
      expect(Redis::Alfred.get(conversation.send(:mute_key))).not_to be_nil
    end

    it 'creates mute message' do
      mute!
      expect(Conversations::ActivityMessageJob)
        .to(have_been_enqueued.at_least(:once).with(conversation, { account_id: conversation.account_id, inbox_id: conversation.inbox_id,
                                                                    message_type: :activity, content: "#{user.name} has muted the conversation" }))
    end
  end

  describe '#unmute!' do
    subject(:unmute!) { conversation.unmute! }

    let(:user) do
      create(:user, email: 'agent2@example.com', account: create(:account), role: :agent)
    end

    let(:conversation) { create(:conversation).tap(&:mute!) }

    before { Current.user = user }

    it 'does not change conversation status' do
      expect { unmute! }.not_to(change { conversation.reload.status })
    end

    it 'marks conversation as muted in redis' do
      expect { unmute! }
        .to change { Redis::Alfred.get(conversation.send(:mute_key)) }
        .to nil
    end

    it 'creates unmute message' do
      unmute!
      expect(Conversations::ActivityMessageJob)
        .to(have_been_enqueued.at_least(:once).with(conversation, { account_id: conversation.account_id, inbox_id: conversation.inbox_id,
                                                                    message_type: :activity, content: "#{user.name} has unmuted the conversation" }))
    end
  end

  describe '#muted?' do
    subject(:muted?) { conversation.muted? }

    let(:conversation) { create(:conversation) }

    it 'return true if conversation is muted' do
      conversation.mute!
      expect(muted?).to be(true)
    end

    it 'returns false if conversation is not muted' do
      expect(muted?).to be(false)
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

  describe 'recent_messages' do
    subject(:recent_messages) { conversation.recent_messages }

    let(:conversation) { create(:conversation, agent_last_seen_at: 1.hour.ago) }
    let(:message_params) do
      {
        conversation: conversation,
        account: conversation.account,
        inbox: conversation.inbox,
        sender: conversation.assignee
      }
    end
    let!(:messages) do
      create_list(:message, 10, **message_params) do |message, i|
        message.created_at = i.minute.ago
      end
    end

    it 'returns upto 5 recent messages' do
      expect(recent_messages.length).to be < 6
      expect(recent_messages).to eq messages.last(5)
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
        additional_attributes: {},
        meta: {
          sender: conversation.contact.push_event_data,
          assignee: conversation.assignee,
          team: conversation.team,
          hmac_verified: conversation.contact_inbox.hmac_verified
        },
        id: conversation.display_id,
        messages: [],
        labels: [],
        inbox_id: conversation.inbox_id,
        status: conversation.status,
        contact_inbox: conversation.contact_inbox,
        timestamp: conversation.last_activity_at.to_i,
        can_reply: true,
        channel: 'Channel::WebWidget',
        snoozed_until: conversation.snoozed_until,
        custom_attributes: conversation.custom_attributes,
        contact_last_seen_at: conversation.contact_last_seen_at.to_i,
        agent_last_seen_at: conversation.agent_last_seen_at.to_i,
        unread_count: 0
      }
    end

    it 'returns push event payload' do
      expect(push_event_data).to eq(expected_data)
    end
  end

  describe '#botinbox: when conversation created inside inbox with agent bot' do
    let!(:bot_inbox) { create(:agent_bot_inbox) }
    let(:conversation) { create(:conversation, inbox: bot_inbox.inbox) }

    it 'returns conversation status as pending' do
      expect(conversation.status).to eq('pending')
    end
  end

  describe '#botintegration: when conversation created in inbox with dialogflow integration' do
    let(:inbox) { create(:inbox) }
    let(:hook) { create(:integrations_hook, :dialogflow, inbox: inbox) }
    let(:conversation) { create(:conversation, inbox: hook.inbox) }

    it 'returns conversation status as pending' do
      expect(conversation.status).to eq('pending')
    end
  end

  describe '#can_reply?' do
    describe 'on channels without 24 hour restriction' do
      let(:conversation) { create(:conversation) }

      it 'returns true' do
        expect(conversation.can_reply?).to be true
      end

      it 'return true for facebook channels' do
        stub_request(:post, /graph.facebook.com/)
        facebook_channel = create(:channel_facebook_page)
        facebook_inbox = create(:inbox, channel: facebook_channel, account: facebook_channel.account)
        fb_conversation = create(:conversation, inbox: facebook_inbox, account: facebook_channel.account)

        expect(fb_conversation.can_reply?).to be true
        expect(facebook_channel.messaging_window_enabled?).to be false
      end
    end

    describe 'on channels with 24 hour restriction' do
      before do
        stub_request(:post, /graph.facebook.com/)
      end

      let!(:facebook_channel) { create(:channel_facebook_page) }
      let!(:facebook_inbox) { create(:inbox, channel: facebook_channel, account: facebook_channel.account) }
      let!(:conversation) { create(:conversation, inbox: facebook_inbox, account: facebook_channel.account) }

      context 'when instagram channel' do
        it 'return true with HUMAN_AGENT if it is outside of 24 hour window' do
          InstallationConfig.where(name: 'ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT').first_or_create(value: true)

          conversation.update(additional_attributes: { type: 'instagram_direct_message' })
          create(
            :message,
            account: conversation.account,
            inbox: facebook_inbox,
            conversation: conversation,
            created_at: Time.now - 48.hours
          )

          expect(conversation.can_reply?).to be true
        end

        it 'return false without HUMAN_AGENT if it is outside of 24 hour window' do
          InstallationConfig.where(name: 'ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT').first_or_create(value: false)

          conversation.update(additional_attributes: { type: 'instagram_direct_message' })
          create(
            :message,
            account: conversation.account,
            inbox: facebook_inbox,
            conversation: conversation,
            created_at: Time.now - 48.hours
          )

          expect(conversation.can_reply?).to be false
        end
      end
    end

    describe 'on API channels' do
      let!(:api_channel) { create(:channel_api, additional_attributes: {}) }
      let!(:api_channel_with_limit) { create(:channel_api, additional_attributes: { agent_reply_time_window: '12' }) }

      context 'when agent_reply_time_window is not configured' do
        it 'return true irrespective of the last message time' do
          conversation = create(:conversation, inbox: api_channel.inbox)
          create(
            :message,
            account: conversation.account,
            inbox: api_channel.inbox,
            conversation: conversation,
            created_at: Time.now - 13.hours
          )

          expect(api_channel.additional_attributes['agent_reply_time_window']).to be_nil
          expect(conversation.can_reply?).to be true
        end
      end

      context 'when agent_reply_time_window is configured' do
        it 'return false if it is outside of agent_reply_time_window' do
          conversation = create(:conversation, inbox: api_channel_with_limit.inbox)
          create(
            :message,
            account: conversation.account,
            inbox: api_channel_with_limit.inbox,
            conversation: conversation,
            created_at: Time.now - 13.hours
          )

          expect(api_channel_with_limit.additional_attributes['agent_reply_time_window']).to eq '12'
          expect(conversation.can_reply?).to be false
        end

        it 'return true if it is inside of agent_reply_time_window' do
          conversation = create(:conversation, inbox: api_channel_with_limit.inbox)
          create(
            :message,
            account: conversation.account,
            inbox: api_channel_with_limit.inbox,
            conversation: conversation
          )
          expect(conversation.can_reply?).to be true
        end
      end
    end
  end

  describe '#delete conversation' do
    include ActiveJob::TestHelper

    let!(:conversation) { create(:conversation) }

    let!(:notification) { create(:notification, notification_type: 'conversation_creation', primary_actor: conversation) }

    it 'delete associated notifications if conversation is deleted' do
      perform_enqueued_jobs do
        conversation.destroy!
      end

      expect { notification.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end

  describe 'validate invalid referer url' do
    let(:conversation) { create(:conversation, additional_attributes: { referer: 'javascript' }) }

    it 'returns nil' do
      expect(conversation['additional_attributes']['referer']).to be_nil
    end
  end

  describe 'validate valid referer url' do
    let(:conversation) { create(:conversation, additional_attributes: { referer: 'https://www.chatwoot.com/' }) }

    it 'returns nil' do
      expect(conversation['additional_attributes']['referer']).to eq('https://www.chatwoot.com/')
    end
  end

  describe 'Custom Sort' do
    include ActiveJob::TestHelper

    let!(:conversation_4) { create(:conversation, created_at: DateTime.now - 10.days, last_activity_at: DateTime.now - 10.days) }
    let!(:conversation_3) { create(:conversation, created_at: DateTime.now - 9.days, last_activity_at: DateTime.now - 9.days) }
    let!(:conversation_1) { create(:conversation, created_at: DateTime.now - 8.days, last_activity_at: DateTime.now - 8.days) }
    let!(:conversation_2) { create(:conversation, created_at: DateTime.now - 6.days, last_activity_at: DateTime.now - 6.days) }

    it 'Sort conversations based on created_at' do
      records = described_class.sort_on_created_at

      expect(records.first.id).to eq(conversation_4.id)
      expect(records.last.id).to eq(conversation_2.id)
    end

    context 'when sort on last_user_message_at' do
      before do
        create(:message, conversation_id: conversation_3.id, message_type: :outgoing, created_at: DateTime.now - 9.days)
        create(:message, conversation_id: conversation_1.id, message_type: :incoming, created_at: DateTime.now - 8.days)
        create(:message, conversation_id: conversation_1.id, message_type: :incoming, created_at: DateTime.now - 8.days)
        create(:message, conversation_id: conversation_1.id, message_type: :outgoing, created_at: DateTime.now - 7.days)
        create(:message, conversation_id: conversation_2.id, message_type: :incoming, created_at: DateTime.now - 6.days)
        create(:message, conversation_id: conversation_2.id, message_type: :incoming, created_at: DateTime.now - 6.days)
        create(:message, conversation_id: conversation_3.id, message_type: :incoming, created_at: DateTime.now - 6.days)
        create(:message, conversation_id: conversation_3.id, message_type: :incoming, created_at: DateTime.now - 6.days)
        create(:message, conversation_id: conversation_3.id, message_type: :incoming, created_at: DateTime.now - 2.days)
      end

      # conversation_2 has last unanswered incoming message 6 days ago
      # conversation_3 has last unanswered incoming message 2 days ago
      # conversation_1 has incoming message 8 days ago but outgoing message on 7 days ago
      # so we won't consider it to show it on top of the sort as it is answered/replied conversation
      it 'Sort conversations with oldest unanswered incoming message first' do
        conversation_with_message_count = described_class.joins(:messages).uniq.count
        records = described_class.last_user_message_at

        expect(records.length).to eq(conversation_with_message_count)
        expect(records[0]['id']).to eq(conversation_2.id)
        expect(records[1]['id']).to eq(conversation_3.id)
        expect(records[2]['id']).to eq(conversation_1.id)
        expect(records.pluck(:id)).not_to include(conversation_4.id)
      end

      # Now we have no incoming message the sprt will happen on the created at
      it 'Sort based on oldest message first when there are no incoming message' do
        Message.where(message_type: :incoming).update(message_type: :template)
        conversation_with_message_count = described_class.joins(:messages).uniq.count
        records = described_class.last_user_message_at

        expect(records.length).to eq(conversation_with_message_count)
        expect(records[0]['id']).to eq(conversation_1.id)
        expect(records[1]['id']).to eq(conversation_2.id)
        expect(records[2]['id']).to eq(conversation_3.id)
      end
    end

    context 'when last_activity_at updated by some actions' do
      before do
        create(:message, conversation_id: conversation_1.id, message_type: :incoming, created_at: DateTime.now - 8.days)
        create(:message, conversation_id: conversation_2.id, message_type: :incoming, created_at: DateTime.now - 6.days)
        create(:message, conversation_id: conversation_3.id, message_type: :incoming, created_at: DateTime.now - 2.days)
      end

      it 'sort conversations with latest resolved conversation at first' do
        records = described_class.latest

        expect(records.first.id).to eq(conversation_3.id)

        conversation_1.toggle_status
        perform_enqueued_jobs do
          Conversations::ActivityMessageJob.perform_later(
            conversation_1,
            account_id: conversation_1.account_id,
            inbox_id: conversation_1.inbox_id,
            message_type: :activity,
            content: 'Conversation was marked resolved by system due to days of inactivity'
          )
        end
        records = described_class.latest

        expect(records.first.id).to eq(conversation_1.id)
      end

      it 'Sort conversations with latest message' do
        create(:message, conversation_id: conversation_3.id, message_type: :incoming, created_at: DateTime.now)
        records = described_class.latest

        expect(records.first.id).to eq(conversation_3.id)
      end
    end
  end
end
