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
        rule.files.attach(io: File.open(Rails.root.join('spec/assets/avatar.png')), filename: 'avatar.png', content_type: 'image/png')
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
        expect(rule.actions.map { |r| r['action_name'] }).to include('send_webhook_event')
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
        expect(rule.actions.map { |r| r['action_name'] }).to include('send_message')
        expect(message_builder).to receive(:perform)
        described_class.new(rule, account, conversation).perform
      end

      it 'will not send message if conversation is a tweet' do
        expect(rule.actions.map { |r| r['action_name'] }).to include('send_message')
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
  end
end
