# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contacts::ReplaceContactPoints do
  let(:account) { create(:account) }
  let(:contact) { account.contacts.new(name: 'Jane Contact') }

  describe '#perform' do
    it 'creates a contact with primary and additional emails and phones' do
      result = described_class.new(
        contact: contact,
        params: {
          email: ' Primary@Example.com ',
          additional_emails: [' Alias@Example.com ', 'second@example.com'],
          phone_number: ' +15551234567 ',
          additional_phones: [' +15557654321 ', '+15559876543']
        }
      ).perform

      expect(result).to be_persisted
      expect(result.email).to eq('primary@example.com')
      expect(result.additional_emails).to eq(%w[alias@example.com second@example.com])
      expect(result.phone_number).to eq('+15551234567')
      expect(result.additional_phones).to eq(%w[+15557654321 +15559876543])
    end

    it 'replaces additional values instead of appending' do
      contact.save!
      create(:contact_email, contact: contact, account: account, email: 'old@example.com')
      create(:contact_phone, contact: contact, account: account, phone_number: '+15550000001')

      described_class.new(
        contact: contact,
        params: {
          additional_emails: %w[new@example.com newer@example.com],
          additional_phones: %w[+15550000002 +15550000003]
        }
      ).perform

      expect(contact.additional_emails).to eq(%w[new@example.com newer@example.com])
      expect(contact.additional_phones).to eq(%w[+15550000002 +15550000003])
    end

    it 'ignores blank values' do
      described_class.new(
        contact: contact,
        params: {
          email: ' ',
          additional_emails: ['alias@example.com', '', nil],
          phone_number: ' ',
          additional_phones: ['+15557654321', '', nil]
        }
      ).perform

      expect(contact.reload.email).to be_nil
      expect(contact.additional_emails).to eq(['alias@example.com'])
      expect(contact.phone_number).to be_nil
      expect(contact.additional_phones).to eq(['+15557654321'])
    end

    it 'dedupes duplicate values in the same payload' do
      described_class.new(
        contact: contact,
        params: {
          email: 'primary@example.com',
          additional_emails: ['Alias@Example.com', 'alias@example.com', 'other@example.com'],
          phone_number: '+15551234567',
          additional_phones: ['+15557654321', '+15557654321', '+15559876543']
        }
      ).perform

      expect(contact.additional_emails).to eq(%w[alias@example.com other@example.com])
      expect(contact.additional_phones).to eq(%w[+15557654321 +15559876543])
    end

    it 'removes primary values from the additional arrays' do
      described_class.new(
        contact: contact,
        params: {
          email: 'primary@example.com',
          additional_emails: %w[alias@example.com primary@example.com],
          phone_number: '+15551234567',
          additional_phones: %w[+15557654321 +15551234567]
        }
      ).perform

      expect(contact.additional_emails).to eq(['alias@example.com'])
      expect(contact.additional_phones).to eq(['+15557654321'])
    end

    it 'uses email_addresses to promote the first value to primary only when email is blank' do
      described_class.new(
        contact: contact,
        params: {
          email: '',
          email_addresses: [' Primary@Example.com ', 'alias@example.com']
        }
      ).perform

      expect(contact.reload.email).to eq('primary@example.com')
      expect(contact.additional_emails).to eq(['alias@example.com'])
    end

    it 'keeps explicit email as primary when email_addresses is present' do
      described_class.new(
        contact: contact,
        params: {
          email: 'explicit@example.com',
          email_addresses: %w[compat-primary@example.com alias@example.com]
        }
      ).perform

      expect(contact.reload.email).to eq('explicit@example.com')
      expect(contact.additional_emails).to eq(%w[compat-primary@example.com alias@example.com])
    end

    it 'uses phone_numbers to promote the first value to primary only when phone_number is blank' do
      described_class.new(
        contact: contact,
        params: {
          phone_number: '',
          phone_numbers: [' +15551234567 ', '+15557654321']
        }
      ).perform

      expect(contact.reload.phone_number).to eq('+15551234567')
      expect(contact.additional_phones).to eq(['+15557654321'])
    end

    it 'keeps explicit phone number as primary when phone_numbers is present' do
      described_class.new(
        contact: contact,
        params: {
          phone_number: '+15550000001',
          phone_numbers: %w[+15550000002 +15550000003]
        }
      ).perform

      expect(contact.reload.phone_number).to eq('+15550000001')
      expect(contact.additional_phones).to eq(%w[+15550000002 +15550000003])
    end

    it 'promotes an existing additional email to primary' do
      contact.update!(email: 'old-primary@example.com')
      create(:contact_email, contact: contact, account: account, email: 'alias@example.com')

      described_class.new(
        contact: contact,
        params: {
          email: 'Alias@Example.com',
          additional_emails: ['old-primary@example.com']
        }
      ).perform

      expect(contact.reload.email).to eq('alias@example.com')
      expect(contact.additional_emails).to eq(['old-primary@example.com'])
    end

    it 'promotes an existing additional phone to primary' do
      contact.update!(phone_number: '+15550000001')
      create(:contact_phone, contact: contact, account: account, phone_number: '+15550000002')

      described_class.new(
        contact: contact,
        params: {
          phone_number: '+15550000002',
          additional_phones: ['+15550000001']
        }
      ).perform

      expect(contact.reload.phone_number).to eq('+15550000002')
      expect(contact.additional_phones).to eq(['+15550000001'])
    end

    it 'lets invalid additional email validation surface' do
      expect do
        described_class.new(
          contact: contact,
          params: { additional_emails: ['not-an-email'] }
        ).perform
      end.to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors.attribute_names).to eq([:email]) }
    end

    it 'lets invalid additional phone validation surface' do
      expect do
        described_class.new(
          contact: contact,
          params: { additional_phones: ['5557654321'] }
        ).perform
      end.to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors.attribute_names).to eq([:phone_number]) }
    end
  end
end
