require 'rails_helper'

RSpec.describe Whatsapp::ContactInfoResponseService do
  subject(:perform) do
    described_class.new(contact_inbox: contact_inbox, message_payload: message_payload).perform
  end

  let(:whatsapp_channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
  end
  let(:inbox) { whatsapp_channel.inbox }
  let(:contact) { create(:contact, account: inbox.account, phone_number: nil) }
  let(:bsuid) { 'AE.2109889333218546' }
  let(:contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact, source_id: bsuid) }
  let(:request_conversation) do
    create(:conversation, account: inbox.account, inbox: inbox, contact: contact, contact_inbox: contact_inbox, status: :resolved)
  end
  let(:response_conversation) do
    create(:conversation, account: inbox.account, inbox: inbox, contact: contact, contact_inbox: contact_inbox)
  end
  let!(:request_message) do
    create(
      :message,
      account: inbox.account,
      inbox: inbox,
      conversation: request_conversation,
      message_type: :outgoing,
      status: :sent,
      created_at: 1.hour.ago,
      content_attributes: {
        whatsapp_contact_info: { type: 'request', state: 'pending', delivery_mode: 'interactive' }
      }
    )
  end
  let(:message_payload) do
    {
      id: 'wamid.contact-info-response',
      from_user_id: bsuid,
      timestamp: Time.current.to_i.to_s,
      contacts: [{
        origin: 'contact_request',
        phones: [{ phone: '+971 54 529 6927', wa_id: '971545296927' }]
      }]
    }.with_indifferent_access
  end

  it 'updates a pending request from a resolved conversation on the same BSUID contact inbox' do
    expect(response_conversation).not_to eq(request_conversation)

    expect(perform).to eq('shared')

    expect(request_message.reload.content_attributes['whatsapp_contact_info']).to include(
      'state' => 'shared',
      'response_source_id' => 'wamid.contact-info-response'
    )
    expect(contact.reload.phone_number).to eq('+971545296927')
    expect(contact_inbox.inbox.contact_inboxes.find_by!(source_id: '971545296927').contact).to eq(contact)
  end

  it 'marks a conflict when the contact was already updated with a different phone' do
    contact.update!(phone_number: '+971500000000')

    expect(perform).to eq('identity_conflict')

    expect(request_message.reload.content_attributes['whatsapp_contact_info']).to include(
      'state' => 'identity_conflict',
      'response_source_id' => 'wamid.contact-info-response'
    )
    expect(contact.reload.phone_number).to eq('+971500000000')
  end

  it 'accepts a parent-only BSUID response' do
    message_payload.delete(:from_user_id)
    message_payload[:from_parent_user_id] = bsuid

    expect(perform).to eq('shared')

    expect(request_message.reload.content_attributes['whatsapp_contact_info']).to include(
      'state' => 'shared',
      'response_source_id' => 'wamid.contact-info-response'
    )
    expect(contact.reload.phone_number).to eq('+971545296927')
  end

  it 'does not use a newer pending request from another BSUID contact inbox on the merged contact' do
    other_contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: 'AE.3109889333218546')
    other_conversation = create(
      :conversation, account: inbox.account, inbox: inbox, contact: contact, contact_inbox: other_contact_inbox
    )
    other_request = create(
      :message,
      account: inbox.account,
      inbox: inbox,
      conversation: other_conversation,
      message_type: :outgoing,
      status: :sent,
      created_at: 30.minutes.ago,
      content_attributes: { whatsapp_contact_info: { type: 'request', state: 'pending' } }
    )

    perform

    expect(request_message.reload.content_attributes.dig('whatsapp_contact_info', 'state')).to eq('shared')
    expect(other_request.reload.content_attributes.dig('whatsapp_contact_info', 'state')).to eq('pending')
  end

  it 'ignores an ordinary shared contact' do
    message_payload[:contacts].first[:origin] = 'other'

    perform

    expect(request_message.reload.content_attributes.dig('whatsapp_contact_info', 'state')).to eq('pending')
    expect(contact.reload.phone_number).to be_nil
  end

  it 'ignores a response that predates the request' do
    message_payload[:timestamp] = (request_message.created_at - 1.minute).to_i.to_s

    perform

    expect(request_message.reload.content_attributes.dig('whatsapp_contact_info', 'state')).to eq('pending')
    expect(contact.reload.phone_number).to be_nil
  end

  it 'does not process the same response twice' do
    service = described_class.new(contact_inbox: contact_inbox, message_payload: message_payload)
    service.perform

    expect { service.perform }.not_to raise_error
    expect(contact_inbox.inbox.contact_inboxes.where(source_id: '971545296927').count).to eq(1)
    expect(request_message.reload.content_attributes['whatsapp_contact_info']).to include(
      'state' => 'shared',
      'response_source_id' => 'wamid.contact-info-response'
    )
  end

  it 'marks the request as an identity conflict without changing the contact' do
    create(:contact, account: inbox.account, phone_number: '+971545296927')

    perform

    expect(request_message.reload.content_attributes['whatsapp_contact_info']).to include(
      'state' => 'identity_conflict',
      'response_source_id' => 'wamid.contact-info-response'
    )
    expect(contact.reload.phone_number).to be_nil
    expect(contact_inbox.inbox.contact_inboxes.find_by(source_id: '971545296927')).to be_nil
  end

  it 'locks the account while assigning the shared phone identity' do
    account = contact.account
    expect(account).to receive(:with_lock).and_call_original

    perform

    expect(contact.reload.phone_number).to eq('+971545296927')
  end
end
