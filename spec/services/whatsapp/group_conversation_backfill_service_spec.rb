require 'rails_helper'

describe Whatsapp::GroupConversationBackfillService do
  subject(:service) { described_class.new(batch_size: 10) }

  let(:account) { create(:account) }
  let(:whatsapp_channel) { create(:channel_whatsapp, account: account, provider: 'unoapi', sync_templates: false, validate_provider_config: false) }
  let(:other_whatsapp_channel) { create(:channel_whatsapp, account: account, phone_number: '+123456700001', provider: 'unoapi', sync_templates: false, validate_provider_config: false) }
  let(:group_contact) { create(:contact, account: account, name: 'Grupo Legado', email: '120363040468224422@g.us') }
  let(:group_contact_inbox) { create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: group_contact, source_id: '120363040468224422@g.us') }
  let(:other_group_contact) { create(:contact, account: account, name: 'Outro Grupo', email: '120363040468224423@g.us') }
  let(:other_group_contact_inbox) { create(:contact_inbox, inbox: other_whatsapp_channel.inbox, contact: other_group_contact, source_id: '120363040468224423@g.us') }
  let(:conversation) do
    create(
      :conversation,
      account: account,
      inbox: whatsapp_channel.inbox,
      contact: group_contact,
      contact_inbox: group_contact_inbox,
      group: false
    )
  end
  let(:sender) { create(:contact, account: account, name: 'Maria', phone_number: '+5566999999999') }

  it 'marks legacy @g.us conversations as groups and creates members from message senders' do
    create(:message, account: account, inbox: whatsapp_channel.inbox, conversation: conversation, sender: sender)
    create(:message, account: account, inbox: whatsapp_channel.inbox, conversation: conversation, sender: group_contact)

    expect(service.perform).to eq(conversations: 1, members: 1)

    conversation.reload
    expect(conversation).to be_group
    expect(conversation.group_source_id).to eq('120363040468224422@g.us')
    expect(conversation.group_title).to eq('Grupo Legado')
    expect(conversation.group_contacts.first.contact).to eq(sender)
  end

  it 'backfills only the selected inbox when inbox is provided' do
    conversation
    other_conversation = create(
      :conversation,
      account: account,
      inbox: other_whatsapp_channel.inbox,
      contact: other_group_contact,
      contact_inbox: other_group_contact_inbox,
      group: false
    )

    described_class.new(batch_size: 10, inbox: whatsapp_channel.inbox).perform

    expect(conversation.reload).to be_group
    expect(other_conversation.reload).not_to be_group
  end
end
