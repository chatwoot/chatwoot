require 'rails_helper'

RSpec.describe Autonomia::Prospecting::ContactConverter do
  let(:account) { create(:account) }
  let(:user) { create(:user, :administrator, account: account) }
  let(:lead) do
    Autonomia::Prospecting::Lead.create!(
      account: account,
      provider: 'mock',
      provider_place_id: 'mock-place-1',
      name: 'Alpha Restaurante',
      phone: '+55 11 99999-8888',
      website: 'https://alpha.example.com',
      address: 'Rua das Flores, 123',
      city: 'Sao Paulo',
      state: 'SP',
      country: 'BR',
      category: 'Restaurante'
    )
  end

  it 'creates a contact and links it to the prospecting lead' do
    result = described_class.new(lead: lead, user: user).perform

    expect(result.created).to be(true)
    expect(result.contact).to be_persisted
    expect(result.contact.name).to eq('Alpha Restaurante')
    expect(result.contact.phone_number).to eq('+5511999998888')
    expect(result.contact.identifier).to eq('prospecting:mock:mock-place-1')
    expect(result.lead.contact_id).to eq(result.contact.id)
  end

  it 'reuses an existing account contact by normalized phone number' do
    contact = create(:contact, account: account, phone_number: '+5511999998888')

    result = described_class.new(lead: lead, user: user).perform

    expect(result.created).to be(false)
    expect(result.contact).to eq(contact)
    expect(result.lead.contact_id).to eq(contact.id)
  end

  it 'returns the linked contact when lead was already converted' do
    contact = create(:contact, account: account, phone_number: '+5511999998888')
    lead.update!(contact: contact)

    result = described_class.new(lead: lead, user: user).perform

    expect(result.created).to be(false)
    expect(result.contact).to eq(contact)
  end
end
