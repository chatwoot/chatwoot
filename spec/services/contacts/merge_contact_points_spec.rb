# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contacts::MergeContactPoints do
  subject(:result) { described_class.new(base_contact: base_contact, mergee_contact: mergee_contact).perform }

  let(:base_contact) do
    instance_double(
      Contact,
      email: ' Base@Example.com ',
      additional_emails: ['Alias@Example.com'],
      phone_number: ' +15551234567 ',
      additional_phones: ['+15557654321']
    )
  end
  let(:mergee_contact) do
    instance_double(
      Contact,
      email: 'Mergee@Example.com',
      additional_emails: ['mergee-alias@example.com'],
      phone_number: '+15559876543',
      additional_phones: ['+15550000001']
    )
  end

  describe '#perform' do
    it 'keeps the base primary email and moves base and mergee secondary emails into additional values' do
      expect(result).to include(
        email: 'base@example.com',
        additional_emails: %w[alias@example.com mergee@example.com mergee-alias@example.com]
      )
    end

    it 'dedupes emails case-insensitively after normalization' do
      allow(base_contact).to receive(:additional_emails).and_return(['ALIAS@Example.com'])
      allow(mergee_contact).to receive(:email).and_return('alias@example.com')
      allow(mergee_contact).to receive(:additional_emails).and_return([' Mergee-Alias@Example.com ', 'mergee-alias@example.com'])

      expect(result[:additional_emails]).to eq(%w[alias@example.com mergee-alias@example.com])
    end

    it 'promotes the mergee primary email when base primary email is blank' do
      allow(base_contact).to receive(:email).and_return(nil)

      expect(result).to include(
        email: 'mergee@example.com',
        additional_emails: %w[alias@example.com mergee-alias@example.com]
      )
    end

    it 'promotes the first additional email when both primary emails are blank' do
      allow(base_contact).to receive(:email).and_return(nil)
      allow(mergee_contact).to receive(:email).and_return(nil)

      expect(result).to include(
        email: 'alias@example.com',
        additional_emails: ['mergee-alias@example.com']
      )
    end

    it 'keeps the base primary phone and moves base and mergee secondary phones into additional values' do
      expect(result).to include(
        phone_number: '+15551234567',
        additional_phones: %w[+15557654321 +15559876543 +15550000001]
      )
    end

    it 'dedupes phones after stripping whitespace' do
      allow(base_contact).to receive(:additional_phones).and_return(['+15557654321'])
      allow(mergee_contact).to receive(:phone_number).and_return(' +15557654321 ')
      allow(mergee_contact).to receive(:additional_phones).and_return([' +15550000001 ', '+15550000001'])

      expect(result[:additional_phones]).to eq(%w[+15557654321 +15550000001])
    end

    it 'promotes the mergee primary phone when base primary phone is blank' do
      allow(base_contact).to receive(:phone_number).and_return(nil)

      expect(result).to include(
        phone_number: '+15559876543',
        additional_phones: %w[+15557654321 +15550000001]
      )
    end

    it 'promotes the first additional phone when both primary phones are blank' do
      allow(base_contact).to receive(:phone_number).and_return(nil)
      allow(mergee_contact).to receive(:phone_number).and_return(nil)

      expect(result).to include(
        phone_number: '+15557654321',
        additional_phones: ['+15550000001']
      )
    end
  end
end
