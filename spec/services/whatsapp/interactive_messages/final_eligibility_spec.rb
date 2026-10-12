require 'rails_helper'

# rubocop:disable RSpec/SpecFilePathFormat
RSpec.describe Whatsapp::SendOnWhatsappService, '#perform final reply-button eligibility check' do
  let(:whatsapp_channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let(:contact) { create(:contact, account: whatsapp_channel.account, phone_number: '+15550000001') }
  let(:contact_inbox) do
    create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: contact, source_id: '15550000001')
  end
  let(:conversation) { create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox) }
  let(:snapshot) { JSON.parse(Rails.root.join('spec/fixtures/whatsapp_interactive_messages/button.json').read) }
  let(:message) do
    create(
      :message,
      conversation: conversation,
      inbox: whatsapp_channel.inbox,
      message_type: :outgoing,
      content: snapshot.dig('body', 'text'),
      content_attributes: { whatsapp_interactive: snapshot }
    )
  end

  before do
    conversation.account.enable_features!(*Whatsapp::InteractiveMessages::Eligibility::TYPE_FEATURES.values)
    create(:message, :incoming, conversation: conversation, inbox: whatsapp_channel.inbox, account: conversation.account)
  end

  it 'fails without provider contact when the type is disabled after message creation' do
    conversation.account.disable_features!('whatsapp_interactive_button')

    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      described_class.new(message: message).perform
    end

    expect(message.reload).to have_attributes(status: 'failed', external_error: 'temporarily_disabled')
    expect(WebMock).not_to have_requested(:post, %r{graph\.facebook\.com/.*/messages})
  end

  it 'fails without provider contact when the service window closes before dispatch' do
    conversation.messages.incoming.update_all(created_at: 25.hours.ago) # rubocop:disable Rails/SkipsModelValidations

    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      described_class.new(message: message).perform
    end

    expect(message.reload).to have_attributes(status: 'failed', external_error: 'service_window_closed')
    expect(WebMock).not_to have_requested(:post, %r{graph\.facebook\.com/.*/messages})
  end

  it 'fails with the same protected-recipient restriction used by capabilities' do
    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000002,+15550000003' do
      described_class.new(message: message).perform
    end

    expect(message.reload).to have_attributes(status: 'failed', external_error: 'test_recipient_not_allowlisted')
    expect(WebMock).not_to have_requested(:post, %r{graph\.facebook\.com/.*/messages})
  end

  it 'retains structured provider evidence when a pending retry becomes ineligible' do
    message.update!(
      status: :pending,
      source_id: nil,
      content_attributes: {
        external_error: 'old provider error',
        whatsapp_interactive: snapshot,
        whatsapp_delivery: {
          retry_count: 1,
          provider_error: { code: 131_000, reason: 'Old provider reason' }
        }
      }
    )
    conversation.account.disable_features!('whatsapp_interactive_button')

    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      described_class.new(message: message).perform
    end

    expect(message.reload).to have_attributes(status: 'failed', external_error: 'temporarily_disabled')
    expect(message.content_attributes['whatsapp_delivery']).to eq(
      'retry_count' => 1,
      'provider_error' => { 'code' => 131_000, 'reason' => 'Old provider reason' }
    )
    expect(WebMock).not_to have_requested(:post, %r{graph\.facebook\.com/.*/messages})
  end

  it 'finishes a pending retry only after the provider returns a new message id' do
    message.update!(
      status: :pending,
      source_id: nil,
      content_attributes: {
        external_error: 'old provider error',
        whatsapp_interactive: snapshot,
        whatsapp_delivery: {
          retry_count: 1,
          provider_error: { code: 131_000, reason: 'Old provider reason' }
        }
      }
    )
    stub_request(:post, 'https://graph.facebook.com/v22.0/123456789/messages')
      .to_return(status: 200, body: { messages: [{ id: 'wamid.retried' }] }.to_json, headers: { 'Content-Type' => 'application/json' })

    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      described_class.new(message: message).perform
    end

    expect(message.reload).to have_attributes(status: 'sent', source_id: 'wamid.retried', external_error: nil)
    expect(message.content_attributes['whatsapp_delivery']).to eq('retry_count' => 1)
  end

  it 'resubmits the identical stored snapshot, delivery ids, and media reference on the same message' do
    attachment = message.attachments.create!(
      account_id: message.account_id,
      file_type: :image,
      file: Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/avatar.png'), 'image/png')
    )
    stored_snapshot = snapshot.deep_dup
    stored_snapshot['header'] = { 'type' => 'image', 'attachment_id' => attachment.id }
    message.update!(
      status: :failed,
      source_id: 'wamid.superseded',
      content_attributes: { whatsapp_interactive: stored_snapshot, whatsapp_delivery: { retry_count: 0 } }
    )
    allow(attachment).to receive(:download_url).and_return('https://media.example.test/avatar.png')
    attachment_scope = message.attachments
    allow(message).to receive(:attachments).and_return(attachment_scope)
    allow(attachment_scope).to receive(:find_by)
      .with(id: attachment.id, account_id: message.account_id)
      .and_return(attachment)
    expected_request_body = {
      messaging_product: 'whatsapp',
      to: '15550000001',
      interactive: {
        type: 'button',
        body: { text: 'Please choose one option.' },
        action: {
          buttons: [
            { type: 'reply', reply: { id: 'reply_00000000-0000-4000-8000-000000000001', title: 'Confirm' } },
            { type: 'reply', reply: { id: 'reply_00000000-0000-4000-8000-000000000002', title: 'Change' } }
          ]
        },
        header: { type: 'image', image: { link: 'https://media.example.test/avatar.png' } }
      },
      type: 'interactive'
    }
    request = stub_request(:post, 'https://graph.facebook.com/v22.0/123456789/messages')
              .with(body: expected_request_body.to_json)
              .to_return(
                status: 200,
                body: { messages: [{ id: 'wamid.retried' }] }.to_json,
                headers: { 'Content-Type' => 'application/json' }
              )

    Whatsapp::InteractiveMessages::RetryService.new(message).perform
    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      described_class.new(message: message).perform
    end

    expect(request).to have_been_requested.once
    expect(message.reload).to have_attributes(id: message.id, status: 'sent', source_id: 'wamid.retried')
    expect(message.content_attributes['whatsapp_interactive']).to eq(stored_snapshot)
    expect(message.reload.attachments.ids).to eq([attachment.id])
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
