require 'rails_helper'

RSpec.describe Line::ContactResolverService do
  let(:channel) { create(:channel_line) }
  let(:inbox) { channel.inbox }
  let(:account) { inbox.account }
  let(:profile) do
    Struct.new(:user_id, :display_name, :picture_url).new(
      'U-line-123',
      'LINE Jane',
      'https://example.com/jane.png'
    )
  end

  it 'reuses an existing contact inbox by source_id' do
    contact_inbox = create(:contact_inbox, inbox: inbox, source_id: 'U-line-123')

    resolved = described_class.new(inbox: inbox, profile: profile).perform

    expect(resolved.id).to eq(contact_inbox.id)
  end

  it 'reuses an existing contact matched by social_line_user_id' do
    contact = create(:contact, account: account, additional_attributes: { 'social_line_user_id' => 'U-line-123' })

    resolved = described_class.new(inbox: inbox, profile: profile).perform

    expect(resolved.contact_id).to eq(contact.id)
    expect(resolved.source_id).to eq('U-line-123')
    expect(contact.reload.custom_attributes['line_handle']).to eq('U-line-123')
  end

  it 'reuses an existing contact matched by custom_attributes line_handle' do
    contact = create(:contact, account: account, custom_attributes: { 'line_handle' => 'U-line-123' })

    resolved = described_class.new(inbox: inbox, profile: profile).perform

    expect(resolved.contact_id).to eq(contact.id)
    expect(contact.reload.additional_attributes['social_line_user_id']).to eq('U-line-123')
  end

  it 'creates a new contact and contact inbox when no match exists' do
    resolved = described_class.new(inbox: inbox, profile: profile).perform

    expect(resolved.contact.custom_attributes['line_handle']).to eq('U-line-123')
    expect(resolved.contact.additional_attributes['social_line_user_id']).to eq('U-line-123')
  end
end
