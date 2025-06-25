require 'rails_helper'

describe ContactDrop do
  subject(:contact_drop) { described_class.new(contact) }

  let!(:contact) { create(:contact) }

  context 'when first name' do
    it 'returns first name' do
      contact.update!(name: 'John Doe')
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
end
