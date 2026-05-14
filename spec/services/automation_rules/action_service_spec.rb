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

    describe '#perform with remove assignment actions' do
      let!(:team) { create(:team, account: account) }

      before do
        conversation.update!(assignee: agent, team: team)
        rule.actions = [
          { action_name: 'remove_assigned_agent', action_params: [] },
          { action_name: 'remove_assigned_team', action_params: [] }
        ]
        rule.save!
      end

      it 'removes assignee and team from the conversation' do
        described_class.new(rule, account, conversation).perform

        expect(conversation.reload.assignee).to be_nil
        expect(conversation.team).to be_nil
      end
    end

    describe '#perform with send_email_transcript action' do
      before do
        allow(account).to receive(:email_transcript_enabled?).and_return(true)
        allow(account).to receive(:within_email_rate_limit?).and_return(true)
        allow(account).to receive(:increment_email_sent_count).and_return(true)
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

    describe '#perform with assign_agent action' do
      before do
        create(:inbox_member, inbox: conversation.inbox, user: agent)
        rule.actions << { action_name: 'assign_agent', action_params: ['last_responding_agent'] }
      end

      it 'assigns the conversation to the last responding agent' do
        create(:message, message_type: :outgoing, account: account,
                         inbox: conversation.inbox, conversation: conversation, sender: agent)

        described_class.new(rule, account, conversation).perform

        expect(conversation.reload.assignee).to eq(agent)
      end
    end

    describe '#perform with send_whatsapp_template action' do
      let(:whatsapp_channel) { create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false) }
      let(:whatsapp_inbox) { whatsapp_channel.inbox }
      let(:email_inbox) { create(:inbox, account: account) }
      let(:contact) { create(:contact, account: account, name: 'Jane Doe', email: 'jane@example.com', phone_number: '+15551234567') }
      # Trigger conversation is on a NON-WhatsApp channel — proving the action is
      # cross-channel: an email rule firing dispatches a WhatsApp template.
      let(:trigger_conversation) { create(:conversation, account: account, inbox: email_inbox, contact: contact) }

      let(:template_config) do
        {
          'inbox_id' => whatsapp_inbox.id,
          'template_name' => 'sample_shipping_confirmation',
          'template_language' => 'en_US',
          'template_namespace' => '23423423_2342423_324234234_2343224',
          'template_category' => 'SHIPPING_UPDATE',
          'template_body' => 'Hi {{1}}, your order ships in {{2}} business days.',
          'processed_params' => { '1' => '{{contact.name}}', '2' => '3' }
        }
      end

      let(:template_rule) do
        create(:automation_rule, account: account,
                                 event_name: 'conversation_created',
                                 actions: [{ action_name: 'send_whatsapp_template', action_params: [template_config] }])
      end

      it 'creates a WhatsApp conversation/message for the contact when triggered on a different channel' do
        expect do
          described_class.new(template_rule, account, trigger_conversation).perform
        end.to change { whatsapp_inbox.conversations.count }.by(1)

        wa_conv = whatsapp_inbox.conversations.last
        expect(wa_conv.contact_id).to eq(contact.id)
        expect(wa_conv.messages.count).to eq(1)

        message = wa_conv.messages.last
        expect(message.additional_attributes['template_params']).to include(
          'name' => 'sample_shipping_confirmation',
          'language' => 'en_US'
        )
        expect(message.additional_attributes['template_params']['processed_params']).to eq('1' => 'Jane Doe', '2' => '3')
        # Body is the rendered template (Liquid drops resolve {{contact.name}} → 'Jane Doe').
        expect(message.content).to eq('Hi Jane Doe, your order ships in 3 business days.')
        expect(message.content_attributes['automation_rule_id']).to eq(template_rule.id)
      end

      it 'no-ops when the contact has no phone number' do
        no_phone = create(:contact, account: account, name: 'Bob', email: 'bob@example.com', phone_number: nil)
        no_phone_conv = create(:conversation, account: account, inbox: email_inbox, contact: no_phone)
        expect do
          described_class.new(template_rule, account, no_phone_conv).perform
        end.not_to(change { whatsapp_inbox.conversations.count })
      end

      it 'no-ops when the configured inbox is not a WhatsApp inbox' do
        template_rule.update_columns(actions: [
                                       {
                                         action_name: 'send_whatsapp_template',
                                         action_params: [template_config.merge('inbox_id' => email_inbox.id)]
                                       }
                                     ])
        expect do
          described_class.new(template_rule.reload, account, trigger_conversation).perform
        end.not_to(change(Message, :count))
      end
    end
  end
end
