require 'rails_helper'

describe Integrations::Slack::UpdateSlackMessageService do
  let(:account) { create(:account) }
  let(:channel_email) { create(:channel_email, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, inbox: channel_email.inbox, contact: contact, identifier: '12345.6789') }
  let(:hook) { create(:integrations_hook, account: account, reference_id: 'C123') }
  let(:slack_client) { double }

  before do
    allow(Slack::Web::Client).to receive(:new).and_return(slack_client)
  end

  describe '#perform' do
    context 'with input_select' do
      it 'updates the Slack message with the submitted response' do
        message = create(
          :message,
          account: account,
          inbox: channel_email.inbox,
          conversation: conversation,
          message_type: :outgoing,
          content_type: :input_select,
          content: 'Pick one',
          content_attributes: {
            items: [{ title: 'Option A', value: 'a' }, { title: 'Option B', value: 'b' }],
            submitted_values: [{ title: 'Option A', value: 'a' }]
          },
          external_source_id_slack: 'cw-origin-6789.12345'
        )

        expect(slack_client).to receive(:chat_update).with(
          channel: 'C123',
          ts: '6789.12345',
          text: a_string_including('Pick one', 'Option A')
        )

        described_class.new(message: message, hook: hook).perform
      end
    end

    context 'with form' do
      it 'updates the Slack message with all submitted fields' do
        message = create(
          :message,
          account: account,
          inbox: channel_email.inbox,
          conversation: conversation,
          message_type: :outgoing,
          content_type: :form,
          content: 'Please fill this',
          content_attributes: {
            items: [{ name: 'email', label: 'Email' }, { name: 'company', label: 'Company' }],
            submitted_values: [{ name: 'email', value: 'a@example.com' }, { name: 'company', value: 'Acme' }]
          },
          external_source_id_slack: 'cw-origin-6789.12345'
        )

        expect(slack_client).to receive(:chat_update).with(
          channel: 'C123',
          ts: '6789.12345',
          text: a_string_including('Please fill this', 'Email', 'a@example.com', 'Company', 'Acme')
        )

        described_class.new(message: message, hook: hook).perform
      end
    end

    context 'with input_csat' do
      it 'updates the Slack message with the CSAT rating and feedback' do
        message = create(
          :message,
          account: account,
          inbox: channel_email.inbox,
          conversation: conversation,
          message_type: :outgoing,
          content_type: :input_csat,
          content: 'Rate us',
          content_attributes: {
            submitted_values: {
              'csat_survey_response' => { 'rating' => 5, 'feedback_message' => 'Great support!' }
            }
          },
          external_source_id_slack: 'cw-origin-6789.12345'
        )

        expect(slack_client).to receive(:chat_update).with(
          channel: 'C123',
          ts: '6789.12345',
          text: a_string_including('Rate us', 'Rating: 5', 'Great support!')
        )

        described_class.new(message: message, hook: hook).perform
      end
    end

    context 'with input_email' do
      it 'updates the Slack message with the submitted email' do
        message = create(
          :message,
          account: account,
          inbox: channel_email.inbox,
          conversation: conversation,
          message_type: :outgoing,
          content_type: :input_email,
          content: 'Get notified by email',
          content_attributes: {
            submitted_email: 'user@example.com'
          },
          external_source_id_slack: 'cw-origin-6789.12345'
        )

        expect(slack_client).to receive(:chat_update).with(
          channel: 'C123',
          ts: '6789.12345',
          text: a_string_including('Get notified by email', 'user@example.com')
        )

        described_class.new(message: message, hook: hook).perform
      end
    end

    context 'when there is no submitted response' do
      it 'skips the update' do
        message = create(
          :message,
          account: account,
          inbox: channel_email.inbox,
          conversation: conversation,
          message_type: :outgoing,
          content_type: :input_select,
          content: 'Pick one',
          content_attributes: {
            items: [{ title: 'Option A', value: 'a' }]
          },
          external_source_id_slack: 'cw-origin-6789.12345'
        )

        expect(slack_client).not_to receive(:chat_update)

        described_class.new(message: message, hook: hook).perform
      end
    end

    context 'when the message was not originated from Chatwoot' do
      it 'skips the update' do
        message = create(
          :message,
          account: account,
          inbox: channel_email.inbox,
          conversation: conversation,
          message_type: :outgoing,
          content_type: :input_select,
          content: 'Pick one',
          content_attributes: {
            items: [{ title: 'Option A', value: 'a' }],
            submitted_values: [{ title: 'Option A', value: 'a' }]
          },
          external_source_id_slack: '6789.12345'
        )

        expect(slack_client).not_to receive(:chat_update)

        described_class.new(message: message, hook: hook).perform
      end
    end

    context 'when hook has no reference_id' do
      it 'skips the update' do
        hook_without_ref = create(:integrations_hook, account: account, reference_id: nil)
        message = create(
          :message,
          account: account,
          inbox: channel_email.inbox,
          conversation: conversation,
          message_type: :outgoing,
          content_type: :input_select,
          content: 'Pick one',
          content_attributes: {
            items: [{ title: 'Option A', value: 'a' }],
            submitted_values: [{ title: 'Option A', value: 'a' }]
          },
          external_source_id_slack: 'cw-origin-6789.12345'
        )

        expect(slack_client).not_to receive(:chat_update)

        described_class.new(message: message, hook: hook_without_ref).perform
      end
    end

    context 'when Slack API raises an auth error' do
      it 'disables the hook and prompts reauthorization' do
        message = create(
          :message,
          account: account,
          inbox: channel_email.inbox,
          conversation: conversation,
          message_type: :outgoing,
          content_type: :input_select,
          content: 'Pick one',
          content_attributes: {
            items: [{ title: 'Option A', value: 'a' }],
            submitted_values: [{ title: 'Option A', value: 'a' }]
          },
          external_source_id_slack: 'cw-origin-6789.12345'
        )

        allow(slack_client).to receive(:chat_update).and_raise(Slack::Web::Api::Errors::AccountInactive.new('account_inactive'))
        allow(hook).to receive(:prompt_reauthorization!)

        described_class.new(message: message, hook: hook).perform

        expect(hook).to have_received(:prompt_reauthorization!)
        expect(hook.reload.status).to eq('disabled')
      end
    end

    context 'when the original Slack message no longer exists' do
      it 'skips gracefully without disabling the hook' do
        message = create(
          :message,
          account: account,
          inbox: channel_email.inbox,
          conversation: conversation,
          message_type: :outgoing,
          content_type: :input_select,
          content: 'Pick one',
          content_attributes: {
            items: [{ title: 'Option A', value: 'a' }],
            submitted_values: [{ title: 'Option A', value: 'a' }]
          },
          external_source_id_slack: 'cw-origin-6789.12345'
        )

        allow(slack_client).to receive(:chat_update).and_raise(Slack::Web::Api::Errors::MessageNotFound.new('message_not_found'))

        described_class.new(message: message, hook: hook).perform

        expect(hook.reload.status).not_to eq('disabled')
      end
    end
  end
end
