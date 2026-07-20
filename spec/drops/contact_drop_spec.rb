require 'rails_helper'

describe ContactDrop do
  subject(:contact_drop) { described_class.new(contact) }

  let!(:contact) { create(:contact, custom_attributes: { car_model: 'Tesla Model S', car_year: '2022' }) }

  context 'when first name' do
    it 'returns first name' do
      contact.update!(name: 'John Doe')
      expect(subject.first_name).to eq 'John'
    end

    it 'returns the single word (capitalized) as first name when name has only one word' do
      contact.update!(name: 'john')
      expect(subject.first_name).to eq 'John'
    end

    it('return the capitalized name') do
      contact.update!(name: 'john doe')
      expect(subject.name).to eq 'John Doe'
    end

    it('return the capitalized first name') do
      contact.update!(name: 'john doe')
      expect(subject.last_name).to eq 'Doe'
    end
  end

  context 'when last name' do
    it 'returns the last name' do
      contact.update!(name: 'John Doe')
      expect(subject.last_name).to eq 'Doe'
    end

    it 'returns empty when last name not present' do
      contact.update!(name: 'John')
      expect(subject.last_name).to be_nil
    end

    it('return the capitalized last name') do
      contact.update!(name: 'john doe')
      expect(subject.last_name).to eq 'Doe'
    end
  end

  context 'when accessing custom attributes' do
    it 'returns the correct car model from custom attributes' do
      expect(contact_drop.custom_attribute['car_model']).to eq 'Tesla Model S'
    end

    it 'returns the correct car year from custom attributes' do
      expect(contact_drop.custom_attribute['car_year']).to eq '2022'
    end

    it 'returns empty hash when there are no custom attributes' do
      contact.update!(custom_attributes: nil)
      expect(contact_drop.custom_attribute).to eq({})
    end
  end

  context 'when accessing additional fields' do
    let!(:agent) { create(:user, account: contact.account, name: 'Agent Smith') }

    it 'exposes phone as alias of phone_number' do
      contact.update!(phone_number: '+1234567890')
      expect(contact_drop.phone).to eq '+1234567890'
      expect(contact_drop.phone_number).to eq '+1234567890'
    end

    it 'exposes document_number' do
      contact.update!(document_number: '12345678')
      expect(contact_drop.document_number).to eq '12345678'
    end

    it 'exposes identifier' do
      contact.update!(identifier: 'ext-99')
      expect(contact_drop.identifier).to eq 'ext-99'
    end

    it 'exposes country_code' do
      contact.update!(country_code: 'AR')
      expect(contact_drop.country_code).to eq 'AR'
    end

    it 'exposes city from additional_attributes' do
      contact.update!(additional_attributes: { 'city' => 'Buenos Aires' })
      expect(contact_drop.city).to eq 'Buenos Aires'
    end

    it 'exposes company_name from additional_attributes' do
      contact.update!(additional_attributes: { 'company_name' => 'Acme SA' })
      expect(contact_drop.company_name).to eq 'Acme SA'
    end

    it 'returns nil for city when additional_attributes is empty' do
      contact.update!(additional_attributes: {})
      expect(contact_drop.city).to be_nil
    end

    it 'exposes assigned_agent as a UserDrop when present' do
      contact.update!(assigned_agent_id: agent.id)
      expect(contact_drop.assigned_agent).to be_a(UserDrop)
      expect(contact_drop.assigned_agent.name).to eq 'Agent Smith'
    end

    it 'returns nil for assigned_agent when not assigned' do
      expect(contact_drop.assigned_agent).to be_nil
    end
  end
end
