require 'rails_helper'

describe ::UserDrop do
  subject(:user_drop) { described_class.new(user) }

  let!(:user) { create(:user) }

  context 'when first name' do
    it 'returns first name' do
      user.update!(name: 'John Doe')
      expect(subject.first_name).to eq 'John'
    end
  end

  it('return the capitalized name') do
    user.update!(name: 'peter')
    expect(subject.name).to eq 'Peter'
  end

  context 'when last name' do
    it 'returns the last name' do
      user.update!(name: 'John Doe')
      expect(subject.last_name).to eq 'Doe'
    end

    it 'returns empty when last name not present' do
      user.update!(name: 'John')
      expect(subject.last_name).to be_nil
    end
  end
end
