require 'rails_helper'

RSpec.describe Sms::TelnyxDeliveryStatusService do
  let(:channel) { create(:channel_telnyx_sms) }
  let(:conversation) { create(:conversation, inbox: channel.inbox) }
  let!(:message) do
    create(:message, conversation: conversation, inbox: channel.inbox, source_id: 'telnyx-message-id', status: :sent)
  end

  it 'marks a finalized message as delivered' do
    params = {
      'id' => message.source_id,
      'to' => [{ 'status' => 'delivered' }]
    }

    described_class.new(inbox: channel.inbox, params: params).perform

    expect(message.reload.status).to eq('delivered')
  end

  it 'marks a failed message as failed and records the error' do
    params = {
      'id' => message.source_id,
      'to' => [{ 'status' => 'failed' }],
      'errors' => [{ 'code' => '40300', 'title' => 'Blocked destination' }]
    }

    described_class.new(inbox: channel.inbox, params: params).perform

    expect(message.reload).to have_attributes(status: 'failed', external_error: '40300 - Blocked destination')
  end
end
