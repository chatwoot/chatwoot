require 'rails_helper'

describe Whatsapp::GroupConversationSchemaMigrationService do
  subject(:service) { described_class.new(batch_size: 10) }

  let(:account) { create(:account) }
  let(:whatsapp_channel) do
    create(
      :channel_whatsapp,
      account: account,
      provider: 'unoapi',
      provider_config: { 'api_key' => 'test_key', 'phone_number_id' => '123456789', 'use_group_conversation_schema' => false },
      sync_templates: false,
      validate_provider_config: false
    )
  end
  let(:group_contact) { create(:contact, account: account, name: 'Grupo Legado', email: '120363040468224422@g.us') }
  let(:group_contact_inbox) { create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: group_contact, source_id: '120363040468224422@g.us') }
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

  before do
    create(:message, account: account, inbox: whatsapp_channel.inbox, conversation: conversation, sender: sender)
  end

  it 'enables structured group schema, backfills legacy groups and marks the inbox as migrated' do
    expect(service.perform).to eq(inboxes: 1, skipped: 0, conversations: 1, members: 1)

    expect(conversation.reload).to be_group
    expect(conversation.group_source_id).to eq('120363040468224422@g.us')
    expect(whatsapp_channel.reload.provider_config).to include(
      'use_group_conversation_schema' => true,
      described_class::MIGRATION_VERSION_KEY => described_class::MIGRATION_VERSION
    )
    expect(whatsapp_channel.provider_config[described_class::MIGRATION_COMPLETED_AT_KEY]).to be_present
  end

  it 'skips inboxes already migrated with the current marker' do
    described_class.mark_migrated!(whatsapp_channel)

    expect(service.perform).to eq(inboxes: 0, skipped: 1, conversations: 0, members: 0)
    expect(conversation.reload).not_to be_group
  end
end
