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

    describe '#perform with send_whatsapp_template action' do
      let(:whatsapp_channel) { create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false) }
      let(:whatsapp_inbox) { whatsapp_channel.inbox }
      let(:other_whatsapp_inbox) do
        create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false).inbox
      end
      let(:contact) { create(:contact, account: account, name: 'Jane Doe', email: 'jane@example.com') }
      let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: '+1234567890') }
      let(:wa_conversation) { create(:conversation, account: account, inbox: whatsapp_inbox, contact: contact, contact_inbox: contact_inbox) }

      let(:template_config) do
        {
          'inbox_ids' => [whatsapp_inbox.id, other_whatsapp_inbox.id],
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

      it 'creates a message with template_params and resolves placeholders' do
        expect do
          described_class.new(template_rule, account, wa_conversation).perform
        end.to change { wa_conversation.messages.count }.by(1)

        message = wa_conversation.messages.last
        expect(message.additional_attributes['template_params']).to include(
          'name' => 'sample_shipping_confirmation',
          'language' => 'en_US'
        )
        expect(message.additional_attributes['template_params']['processed_params']).to eq('1' => 'Jane Doe', '2' => '3')
        expect(message.content).to eq('Hi Jane Doe, your order ships in 3 business days.')
        expect(message.content_attributes['automation_rule_id']).to eq(template_rule.id)
      end

      it 'no-ops when the conversation is not on a configured inbox' do
        unrelated_conversation = create(:conversation, account: account)
        expect do
          described_class.new(template_rule, account, unrelated_conversation).perform
        end.not_to(change { unrelated_conversation.messages.count })
      end

      it 'no-ops when the conversation is not on a WhatsApp inbox at all' do
        non_wa_inbox = create(:inbox, account: account)
        non_wa_conversation = create(:conversation, account: account, inbox: non_wa_inbox)
        # Make the action target this non-WA inbox to prove the channel check
        # wins regardless of inbox_ids membership.
        template_rule.update_columns(actions: [
                                       {
                                         action_name: 'send_whatsapp_template',
                                         action_params: [template_config.merge('inbox_ids' => [non_wa_inbox.id])]
                                       }
                                     ])
        expect do
          described_class.new(template_rule.reload, account, non_wa_conversation).perform
        end.not_to(change { non_wa_conversation.messages.count })
      end
    end
  end
end
