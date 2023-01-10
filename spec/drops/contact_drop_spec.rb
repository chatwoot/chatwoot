require 'rails_helper'

describe ::ContactDrop do
  subject(:contact_drop) { described_class.new(contact) }

  let!(:contact) { create(:contact) }

  context 'when first name' do
    it 'returns first name' do
      contact.update!(name: 'John Doe')
      expect(subject.first_name).to eq 'John'
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
  end
end
