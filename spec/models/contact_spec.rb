# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contact do
  context 'validations' do
    it { is_expected.to validate_presence_of(:account_id) }
  end

  context 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:conversations).dependent(:destroy_async) }
  end

  context 'prepare contact attributes before validation' do
    it 'sets email to lowercase' do
      contact = create(:contact, email: 'Test@test.com')
      expect(contact.email).to eq('test@test.com')
    end

    it 'sets email to nil when empty string' do
      contact = create(:contact, email: '')
      expect(contact.email).to be_nil
    end

    it 'sets custom_attributes to {} when nil' do
      contact = create(:contact, custom_attributes: nil)
      expect(contact.custom_attributes).to eq({})
    end

    it 'sets custom_attributes to {} when empty string' do
      contact = create(:contact, custom_attributes: '')
      expect(contact.custom_attributes).to eq({})
    end

    it 'sets additional_attributes to {} when nil' do
      contact = create(:contact, additional_attributes: nil)
      expect(contact.additional_attributes).to eq({})
    end

    it 'sets additional_attributes to {} when empty string' do
      contact = create(:contact, additional_attributes: '')
      expect(contact.additional_attributes).to eq({})
    end
  end

  # rubocop:disable Rails/SkipsModelValidations
  context 'when phone number format' do
    it 'will not throw error for existing invalid phone number' do
      contact = create(:contact)
      contact.update_column(:phone_number, '344234')
      contact.reload
      expect(contact.update!(name: 'test')).to eq true
      expect(contact.phone_number).to eq '344234'
    end

    it 'updates phone number when adding valid phone number' do
      contact = create(:contact)
      contact.update_column(:phone_number, '344234')
      contact.reload
      expect(contact.update!(phone_number: '+12312312321')).to eq true
      expect(contact.phone_number).to eq '+12312312321'
    end
  end

  context 'when email format' do
    it 'will not throw error for existing invalid email' do
      contact = create(:contact)
      contact.update_column(:email, 'ssfdasdf <test@test')
      contact.reload
      expect(contact.update!(name: 'test')).to eq true
      expect(contact.email).to eq 'ssfdasdf <test@test'
    end

    it 'updates email when adding valid email' do
      contact = create(:contact)
      contact.update_column(:email, 'ssfdasdf <test@test')
      contact.reload
      expect(contact.update!(email: 'test@test.com')).to eq true
      expect(contact.email).to eq 'test@test.com'
    end
  end
  # rubocop:enable Rails/SkipsModelValidations
end
