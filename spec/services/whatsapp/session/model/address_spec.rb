require 'rails_helper'

RSpec.describe Whatsapp::Session::Model::Address do
  describe '.parse' do
    it 'reads the kind from the jid server' do
      expect(described_class.parse('5541999990000@s.whatsapp.net')).to have_attributes(kind: 'phone', id: '5541999990000')
      expect(described_class.parse('182736451928374@lid')).to have_attributes(kind: 'lid', id: '182736451928374')
      expect(described_class.parse('120363041234567890@g.us')).to have_attributes(kind: 'group', id: '120363041234567890')
      expect(described_class.parse('0@newsletter')).to have_attributes(kind: 'newsletter')
    end

    it 'tells the status broadcast apart from a regular broadcast list' do
      expect(described_class.parse('status@broadcast').kind).to eq('status')
      expect(described_class.parse('123456@broadcast').kind).to eq('broadcast')
    end

    it 'drops the device and agent parts' do
      expect(described_class.parse('5541999990000:12@s.whatsapp.net').id).to eq('5541999990000')
      expect(described_class.parse('5541999990000_1:3@s.whatsapp.net').id).to eq('5541999990000')
    end

    it 'returns nil for a blank jid' do
      expect(described_class.parse(nil)).to be_nil
      expect(described_class.parse('')).to be_nil
    end

    it 'refuses an unknown server' do
      expect { described_class.parse('5541999990000@example.com') }.to raise_error(Whatsapp::Session::Errors::InvalidPayload)
    end
  end

  describe '.for_contact' do
    let(:account) { create(:account) }

    it 'prefers the identifier, which is what the provider echoes back' do
      contact = create(:contact, account: account, phone_number: '+5541999990000', identifier: '182736451928374@lid')

      expect(described_class.for_contact(contact)).to have_attributes(kind: 'lid', id: '182736451928374')
    end

    it 'falls back to the phone number without the plus sign' do
      contact = create(:contact, account: account, phone_number: '+5541999990000', identifier: nil)

      expect(described_class.for_contact(contact)).to have_attributes(kind: 'phone', id: '5541999990000')
    end

    it 'addresses a group by its jid' do
      contact = create(:contact, account: account, phone_number: nil, identifier: '120363041234567890@g.us')

      expect(described_class.for_contact(contact)).to have_attributes(kind: 'group', id: '120363041234567890')
    end
  end

  it 'rebuilds the jid it was parsed from' do
    %w[5541999990000@s.whatsapp.net 182736451928374@lid 120363041234567890@g.us status@broadcast].each do |jid|
      expect(described_class.parse(jid).to_jid).to eq(jid)
    end
  end

  it 'knows which chats never become conversations' do
    expect(described_class.parse('status@broadcast')).to be_ignorable
    expect(described_class.parse('5541999990000@s.whatsapp.net')).not_to be_ignorable
  end

  it 'refuses an unknown kind or a blank id' do
    expect { described_class.new(kind: 'satellite', id: '1') }.to raise_error(Whatsapp::Session::Errors::InvalidPayload)
    expect { described_class.new(kind: 'phone', id: '') }.to raise_error(Whatsapp::Session::Errors::InvalidPayload)
  end
end
