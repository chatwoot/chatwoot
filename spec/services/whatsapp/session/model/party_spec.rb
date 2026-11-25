require 'rails_helper'

RSpec.describe Whatsapp::Session::Model::Party do
  subject(:party) { described_class.new(phone: '+5541999990000', lid: '182736451928374@lid', push_name: 'Ana') }

  it 'normalizes the phone and the lid it was built with' do
    expect(party.phone).to eq('5541999990000')
    expect(party.lid).to eq('182736451928374')
  end

  it 'identifies the contact by lid, as the Baileys layer already does' do
    expect(party.source_id).to eq('182736451928374')
    expect(party.identifier).to eq('182736451928374@lid')
    expect(party.address).to have_attributes(kind: 'lid', id: '182736451928374')
  end

  it 'falls back to the phone when there is no lid' do
    phone_only = described_class.new(phone: '5541999990000')

    expect(phone_only.source_id).to eq('5541999990000')
    expect(phone_only.identifier).to be_nil
    expect(phone_only.address).to have_attributes(kind: 'phone', id: '5541999990000')
    expect(phone_only.phone_e164).to eq('+5541999990000')
  end

  it 'prefers the verified business name over the push name' do
    expect(described_class.new(phone: '55419', push_name: 'Ana', verified_name: 'Ana LTDA').name).to eq('Ana LTDA')
    expect(party.name).to eq('Ana')
  end

  it 'round-trips through the wire payload' do
    expect(described_class.from_h(party.to_h)).to eq(party)
  end
end
