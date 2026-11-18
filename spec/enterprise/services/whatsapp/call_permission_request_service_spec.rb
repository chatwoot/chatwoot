require 'rails_helper'

describe Whatsapp::CallPermissionRequestService do
  let(:account) { create(:account) }
  let(:channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', account: account,
                              validate_provider_config: false, sync_templates: false)
  end
  let(:inbox) { channel.inbox }
  let(:contact) { create(:contact, account: account, phone_number: '+15551234567') }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox, source_id: 'IN.2081978709342942') }
  let(:conversation) do
    create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox).tap(&:reload)
  end
  let(:provider_service) { instance_double(Whatsapp::Providers::WhatsappCloudService) }

  before do
    allow(Whatsapp::Providers::WhatsappCloudService).to receive(:new).and_return(provider_service)
    allow(Conversations::ActivityMessageJob).to receive(:perform_later)
  end

  it 'throttles permission requests for the same recipient' do
    allow(provider_service).to receive(:send_call_permission_request)
      .with('IN.2081978709342942')
      .and_return({ 'messages' => [{ 'id' => 'wamid.req_bsuid' }] })

    first_status = described_class.new(conversation: conversation, recipient: 'IN.2081978709342942', window_open: true).perform
    second_status = described_class.new(conversation: conversation, recipient: 'IN.2081978709342942', window_open: true).perform

    expect(first_status).to eq('permission_requested')
    expect(second_status).to eq('permission_pending')
    expect(provider_service).to have_received(:send_call_permission_request).once
  end

  it 'throttles pre-upgrade permission requests stored directly on the conversation' do
    conversation.update!(
      additional_attributes: {
        'call_permission_requested_at' => Time.current.iso8601,
        'call_permission_request_message_id' => 'wamid.legacy_req'
      }
    )

    expect(provider_service).not_to receive(:send_call_permission_request)

    status = described_class.new(conversation: conversation, recipient: '15551234567', window_open: true).perform

    expect(status).to eq('permission_pending')
  end

  it 'does not throttle another recipient on the same conversation' do
    allow(provider_service).to receive(:send_call_permission_request)
      .with('IN.2081978709342942')
      .and_return({ 'messages' => [{ 'id' => 'wamid.req_bsuid' }] })
    allow(provider_service).to receive(:send_call_permission_request)
      .with('15551234567')
      .and_return({ 'messages' => [{ 'id' => 'wamid.req_phone' }] })

    described_class.new(conversation: conversation, recipient: 'IN.2081978709342942', window_open: true).perform
    status = described_class.new(conversation: conversation, recipient: '15551234567', window_open: true).perform

    attrs = conversation.reload.additional_attributes
    expect(status).to eq('permission_requested')
    expect(attrs['call_permission_requests']).to include(
      'IN.2081978709342942' => include('call_permission_request_message_id' => 'wamid.req_bsuid'),
      '15551234567' => include('call_permission_request_message_id' => 'wamid.req_phone')
    )
  end

  context 'when the contact has not messaged in the last 24 hours' do
    let(:template) { channel.call_permission_template }

    it "sends the inbox's call permission template and remembers its wamid for the reply" do
      allow(provider_service).to receive(:send_call_permission_template)
        .with('15551234567', name: template.name, language: template.language)
        .and_return({ 'messages' => [{ 'id' => 'wamid.template_req' }] })

      status = described_class.new(conversation: conversation, recipient: '15551234567', window_open: false).perform

      expect(status).to eq('permission_requested')
      expect(conversation.reload.additional_attributes['call_permission_request_message_id']).to eq('wamid.template_req')
    end

    it 'reports the template as unavailable when Meta will not send it' do
      allow(provider_service).to receive(:send_call_permission_template).and_return(nil)

      expect(described_class.new(conversation: conversation, recipient: '15551234567', window_open: false).perform).to eq('template_unavailable')
      expect(Conversations::ActivityMessageJob).not_to have_received(:perform_later)
    end
  end
end
