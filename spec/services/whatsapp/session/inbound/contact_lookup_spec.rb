require 'rails_helper'

RSpec.describe Whatsapp::Session::Inbound::ContactLookup do
  subject(:found) { described_class.find(inbox: inbox, party: party) }

  let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:model) { Whatsapp::Session::Model }
  let(:party) { model::Party.new(phone: '5541999990000', lid: '182736451928374') }
  let(:contact) { create(:contact, account: channel.account, name: 'Ana Souza', phone_number: '+5541999990000') }

  it 'answers nil for a party nobody here knows' do
    expect(found).to be_nil
  end

  it 'finds the row the event names' do
    contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: '182736451928374')

    expect(found).to eq(contact_inbox)
  end

  # Both keys hold a row until consolidation merges them, and an unordered match could
  # answer with the phone-keyed copy that is on its way out. `Party#source_id` makes the
  # LID the canonical key, so it wins.
  it 'prefers the LID while a phone-keyed row still exists' do
    obsolete = create(:contact, account: channel.account, name: 'Ana antiga')
    create(:contact_inbox, inbox: inbox, contact: obsolete, source_id: '5541999990000')
    canonical = create(:contact_inbox, inbox: inbox, contact: contact, source_id: '182736451928374')

    expect(found).to eq(canonical)
  end

  it 'falls back to the other ninth-digit form of the source id' do
    contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: '554199990000')

    expect(described_class.find(inbox: inbox, party: model::Party.new(phone: '5541999990000'))).to eq(contact_inbox)
  end

  # Consolidation re-keys the row to the LID, so a party named only by phone matches no
  # source_id at all and the number on the contact is the last thing left to match on.
  it 'falls back to the phone stored on the contact' do
    contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: '182736451928374')

    expect(described_class.find(inbox: inbox, party: model::Party.new(phone: '5541999990000'))).to eq(contact_inbox)
  end

  it 'never invents a contact' do
    expect { found }.not_to change(Contact, :count)
  end
end
