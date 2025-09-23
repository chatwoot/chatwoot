require 'rails_helper'

RSpec.describe AutomationRules::ActionService do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account) }
  let(:conversation) { create(:conversation, account: account) }
  let!(:rule) do
    create(:automation_rule, account: account,
                             actions: [
                               { action_name: 'send_webhook_event', action_params: ['https://example.com'] },
                               { action_name: 'send_message', action_params: { message: 'Hello' } }
                             ])
  end

  describe '#perform' do
    context 'when actions are defined in the rule' do
      it 'will call the actions' do
        expect(Messages::MessageBuilder).to receive(:new)
        expect(WebhookJob).to receive(:perform_later)
        described_class.new(rule, account, conversation).perform
      end
    end

    describe '#perform with send_attachment action' do
      let(:message_builder) { double }

      before do
        allow(Messages::MessageBuilder).to receive(:new).and_return(message_builder)
        rule.actions.delete_if { |a| a['action_name'] == 'send_message' }
        rule.files.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
        rule.save!
        rule.actions << { action_name: 'send_attachment', action_params: [rule.files.first.blob_id] }
      end

      it 'will send attachment' do
        expect(message_builder).to receive(:perform)
        described_class.new(rule, account, conversation).perform
      end

      it 'will not send attachment is conversation is a tweet' do
        twitter_inbox = create(:inbox, channel: create(:channel_twitter_profile, account: account))
        conversation = create(:conversation, inbox: twitter_inbox, additional_attributes: { type: 'tweet' })
        expect(message_builder).not_to receive(:perform)
        described_class.new(rule, account, conversation).perform
      end
    end

    describe '#perform with send_webhook_event action' do
      it 'will send webhook event' do
        expect(rule.actions.pluck('action_name')).to include('send_webhook_event')
        expect(WebhookJob).to receive(:perform_later)
        described_class.new(rule, account, conversation).perform
      end
    end

    describe '#perform with send_message action' do
      let(:message_builder) { double }

      before do
        allow(Messages::MessageBuilder).to receive(:new).and_return(message_builder)
      end

      it 'will send message' do
        expect(rule.actions.pluck('action_name')).to include('send_message')
        expect(message_builder).to receive(:perform)
        described_class.new(rule, account, conversation).perform
      end

      it 'will not send message if conversation is a tweet' do
        expect(rule.actions.pluck('action_name')).to include('send_message')
        twitter_inbox = create(:inbox, channel: create(:channel_twitter_profile, account: account))
        conversation = create(:conversation, inbox: twitter_inbox, additional_attributes: { type: 'tweet' })
        expect(message_builder).not_to receive(:perform)
        described_class.new(rule, account, conversation).perform
      end
    end

    describe '#perform with send_email_to_team action' do
      let!(:team) { create(:team, account: account) }

      before do
        rule.actions << { action_name: 'send_email_to_team', action_params: [{ team_ids: [team.id], message: 'Hello' }] }
      end

      it 'will send email to team' do
        expect(TeamNotifications::AutomationNotificationMailer).to receive(:conversation_creation).with(conversation, team, 'Hello').and_call_original
        described_class.new(rule, account, conversation).perform
      end
    end

    describe '#perform with send_email_transcript action' do
      before do
        rule.actions << { action_name: 'send_email_transcript', action_params: ['contact@example.com, agent@example.com,agent1@example.com'] }
        rule.save
      end

      it 'will send email to transcript to action params emails' do
        mailer = double
        allow(ConversationReplyMailer).to receive(:with).and_return(mailer)
        allow(mailer).to receive(:conversation_transcript).with(conversation, 'contact@example.com')
        allow(mailer).to receive(:conversation_transcript).with(conversation, 'agent@example.com')
        allow(mailer).to receive(:conversation_transcript).with(conversation, 'agent1@example.com')

        described_class.new(rule, account, conversation).perform
        expect(mailer).to have_received(:conversation_transcript).exactly(3).times
      end

      it 'will send email to transcript to contacts' do
        rule.actions = [{ action_name: 'send_email_transcript', action_params: ['{{contact.email}}'] }]
        rule.save

        mailer = double
        allow(ConversationReplyMailer).to receive(:with).and_return(mailer)
        allow(mailer).to receive(:conversation_transcript).with(conversation, conversation.contact.email)

        described_class.new(rule.reload, account, conversation).perform
        expect(mailer).to have_received(:conversation_transcript).exactly(1).times
      end
    end

    describe '#perform with add_label action' do
      before do
        rule.actions << { action_name: 'add_label', action_params: %w[bug feature] }
        rule.save
      end

      it 'will add labels to conversation' do
        described_class.new(rule, account, conversation).perform
        expect(conversation.reload.label_list).to include('bug', 'feature')
      end

      it 'will not duplicate existing labels' do
        conversation.add_labels(['bug'])
        described_class.new(rule, account, conversation).perform
        expect(conversation.reload.label_list.count('bug')).to eq(1)
        expect(conversation.reload.label_list).to include('feature')
      end
    end

    describe '#perform with remove_label action' do
      before do
        conversation.add_labels(%w[bug feature support])
        rule.actions << { action_name: 'remove_label', action_params: %w[bug feature] }
        rule.save
      end

      it 'will remove specified labels from conversation' do
        described_class.new(rule, account, conversation).perform
        expect(conversation.reload.label_list).not_to include('bug', 'feature')
        expect(conversation.reload.label_list).to include('support')
      end

      it 'will not fail if labels do not exist on conversation' do
        conversation.update_labels(['support']) # Remove bug and feature first
        expect { described_class.new(rule, account, conversation).perform }.not_to raise_error
        expect(conversation.reload.label_list).to include('support')
      end
    end

    describe '#perform with add_private_note action' do
      let(:message_builder) { double }

      before do
        allow(Messages::MessageBuilder).to receive(:new).and_return(message_builder)
        rule.actions.delete_if { |a| a['action_name'] == 'send_message' }
        rule.actions << { action_name: 'add_private_note', action_params: ['Note'] }
      end

      it 'will add private note' do
        expect(message_builder).to receive(:perform)
        described_class.new(rule, account, conversation).perform
      end

      it 'will not add note if conversation is a tweet' do
        twitter_inbox = create(:inbox, channel: create(:channel_twitter_profile, account: account))
        conversation = create(:conversation, inbox: twitter_inbox, additional_attributes: { type: 'tweet' })
        expect(message_builder).not_to receive(:perform)
        described_class.new(rule, account, conversation).perform
      end
    end
  end
end
