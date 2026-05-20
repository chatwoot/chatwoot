require 'rails_helper'

describe Whatsapp::CallPermissionReplyService do
  let(:account) { create(:account) }
  let(:channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', account: account,
                              validate_provider_config: false, sync_templates: false)
  end
  let(:inbox) { channel.inbox }
  let(:contact) { create(:contact, account: account, phone_number: '+15550001111') }
  let!(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox, source_id: '15550001111') }
  let(:request_wamid) { 'wamid.permission_request_abc' }
  let!(:conversation) do
    create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox, status: :open,
                          additional_attributes: {
                            'call_permission_requested_at' => Time.current.iso8601,
                            'call_permission_request_message_id' => request_wamid
                          })
  end

  before do
    account.enable_features!('channel_voice')
    channel.provider_config = channel.provider_config.merge('source' => 'embedded_signup', 'calling_enabled' => true)
    channel.save!
  end

  def reply_params(response:, context_id: request_wamid)
    interactive = { type: 'call_permission_reply',
                    call_permission_reply: { response: response, is_permanent: false } }
    message = { from: '15550001111', type: 'interactive', interactive: interactive }
    message[:context] = { id: context_id } if context_id
    { entry: [{ changes: [{ value: { messages: [message] } }] }] }
  end

  it 'clears both permission flags and broadcasts voice_call.permission_granted on accept' do
    allow(ActionCable.server).to receive(:broadcast)

    described_class.new(inbox: inbox, params: reply_params(response: 'accept')).perform

    attrs = conversation.reload.additional_attributes
    expect(attrs).not_to include('call_permission_requested_at')
    expect(attrs).not_to include('call_permission_request_message_id')
    expect(ActionCable.server).to have_received(:broadcast).with(
      "account_#{account.id}",
      hash_including(event: 'voice_call.permission_granted',
                     data: hash_including(conversation_id: conversation.id))
    )
  end

  it 'is a no-op when the contact rejected the request' do
    allow(ActionCable.server).to receive(:broadcast)

    described_class.new(inbox: inbox, params: reply_params(response: 'reject')).perform

    expect(conversation.reload.additional_attributes).to include('call_permission_requested_at')
    expect(ActionCable.server).not_to have_received(:broadcast)
  end

  it 'is a no-op when calling is disabled on the channel' do
    channel.provider_config = channel.provider_config.merge('calling_enabled' => false)
    channel.save!
    allow(ActionCable.server).to receive(:broadcast)

    described_class.new(inbox: inbox, params: reply_params(response: 'accept')).perform

    expect(ActionCable.server).not_to have_received(:broadcast)
  end

  it 'matches the originating conversation by context.id when the contact has multiple pending requests' do
    other_request_wamid = 'wamid.permission_request_xyz'
    other_open = create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox,
                                       status: :open,
                                       additional_attributes: {
                                         'call_permission_requested_at' => Time.current.iso8601,
                                         'call_permission_request_message_id' => other_request_wamid
                                       })
    allow(ActionCable.server).to receive(:broadcast)

    described_class.new(inbox: inbox, params: reply_params(response: 'accept', context_id: other_request_wamid)).perform

    # The reply pointed at other_open's request — it should be the cleared one, not `conversation`
    expect(other_open.reload.additional_attributes).not_to include('call_permission_request_message_id')
    expect(conversation.reload.additional_attributes).to include('call_permission_request_message_id')
    expect(ActionCable.server).to have_received(:broadcast).with(
      "account_#{account.id}",
      hash_including(data: hash_including(conversation_id: other_open.id))
    )
  end

  it 'is a no-op when the reply has no context.id' do
    allow(ActionCable.server).to receive(:broadcast)

    described_class.new(inbox: inbox, params: reply_params(response: 'accept', context_id: nil)).perform

    expect(conversation.reload.additional_attributes).to include('call_permission_request_message_id')
    expect(ActionCable.server).not_to have_received(:broadcast)
  end
end
