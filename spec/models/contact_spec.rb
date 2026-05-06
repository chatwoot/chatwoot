# frozen_string_literal: true

require 'rails_helper'

require Rails.root.join 'spec/models/concerns/avatarable_shared.rb'

RSpec.describe Contact do
  context 'with validations' do
    it { is_expected.to validate_presence_of(:account_id) }
  end

  context 'with associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:conversations).dependent(:destroy_async) }
  end

  describe 'concerns' do
    it_behaves_like 'avatarable'

    it 'accepts webp avatars' do
      contact = build(:contact, account: create(:account))
      contact.avatar.attach(get_blob_for(Rails.root.join('spec/assets/avatar.png'), 'image/webp'))

      expect(contact).to be_valid
    end
  end

  context 'when prepare contact attributes before validation' do
    it 'sets email to lowercase' do
      contact = create(:contact, email: 'Test@test.com')
      expect(contact.email).to eq('test@test.com')
      expect(contact.contact_type).to eq('lead')
    end

    it 'sets email to nil when empty string' do
      contact = create(:contact, email: '')
      expect(contact.email).to be_nil
      expect(contact.contact_type).to eq('visitor')
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

  context 'when phone number format' do
    it 'will throw error for existing invalid phone number' do
      contact = create(:contact)
      expect { contact.update!(phone_number: '123456789') }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'updates phone number when adding valid phone number' do
      contact = create(:contact)
      expect(contact.update!(phone_number: '+12312312321')).to be true
      expect(contact.phone_number).to eq '+12312312321'
    end
  end

  context 'when email format' do
    it 'will throw error for existing invalid email' do
      contact = create(:contact)
      expect { contact.update!(email: '<2324234234') }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'updates email when adding valid email' do
      contact = create(:contact)
      expect(contact.update!(email: 'test@test.com')).to be true
      expect(contact.email).to eq 'test@test.com'
    end
  end

  describe 'contact points' do
    let(:account) { create(:account) }

    it "does not allow a primary email to duplicate another contact's additional email" do
      contact = create(:contact, account: account, email: 'owner@example.com')
      create(:contact_email, contact: contact, account: account, email: 'alias@example.com')

      duplicate = build(:contact, account: account, email: 'alias@example.com')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to be_present
    end

    it 'does not allow the primary email to duplicate its own additional email' do
      contact = create(:contact, account: account, email: 'owner@example.com')
      contact_email = create(:contact_email, contact: contact, account: account, email: 'alias@example.com')

      contact.email = 'alias@example.com'

      expect(contact).not_to be_valid
      expect(contact.errors[:email]).to be_present

      contact_email.destroy!
      expect(contact).to be_valid
    end

    it "does not allow a primary phone to duplicate another contact's additional phone" do
      contact = create(:contact, account: account, phone_number: '+15551234567')
      create(:contact_phone, contact: contact, account: account, phone_number: '+15557654321')

      duplicate = build(:contact, account: account, phone_number: '+15557654321')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:phone_number]).to be_present
    end

    it 'does not allow the primary phone to duplicate its own additional phone' do
      contact = create(:contact, account: account, phone_number: '+15551234567')
      contact_phone = create(:contact_phone, contact: contact, account: account, phone_number: '+15557654321')

      contact.phone_number = '+15557654321'

      expect(contact).not_to be_valid
      expect(contact.errors[:phone_number]).to be_present

      contact_phone.destroy!
      expect(contact).to be_valid
    end

    it 'returns all emails with primary first' do
      contact = create(:contact, account: account, email: 'primary@example.com')
      create(:contact_email, contact: contact, account: account, email: 'second@example.com')
      create(:contact_email, contact: contact, account: account, email: 'third@example.com')

      expect(contact.all_emails).to eq(%w[primary@example.com second@example.com third@example.com])
    end

    it 'returns all phone numbers with primary first' do
      contact = create(:contact, account: account, phone_number: '+15551234567')
      create(:contact_phone, contact: contact, account: account, phone_number: '+15557654321')
      create(:contact_phone, contact: contact, account: account, phone_number: '+15559876543')

      expect(contact.all_phone_numbers).to eq(%w[+15551234567 +15557654321 +15559876543])
    end
  end

  describe '.matching_email' do
    let(:account) { create(:account) }

    it 'finds contacts by primary and additional emails' do
      primary_contact = create(:contact, account: account, email: 'primary@example.com')
      additional_contact = create(:contact, account: account, email: 'owner@example.com')
      create(:contact_email, contact: additional_contact, account: account, email: 'alias@example.com')

      expect(account.contacts.matching_email(' PRIMARY@example.com ')).to contain_exactly(primary_contact)
      expect(account.contacts.matching_email('ALIAS@example.com')).to contain_exactly(additional_contact)
    end
  end

  describe '.matching_phone_number' do
    let(:account) { create(:account) }

    it 'finds contacts by primary and additional phone numbers' do
      primary_contact = create(:contact, account: account, phone_number: '+15551234567')
      additional_contact = create(:contact, account: account, phone_number: '+15557654321')
      create(:contact_phone, contact: additional_contact, account: account, phone_number: '+15559876543')

      expect(account.contacts.matching_phone_number(' +15551234567 ')).to contain_exactly(primary_contact)
      expect(account.contacts.matching_phone_number('+15559876543')).to contain_exactly(additional_contact)
    end

    it 'includes contact point arrays in push event data' do
      contact = create(:contact, account: account, email: 'primary@example.com', phone_number: '+15551234567')
      create(:contact_email, contact: contact, account: account, email: 'alias@example.com')
      create(:contact_phone, contact: contact, account: account, phone_number: '+15557654321')

      expect(contact.push_event_data).to include(
        additional_emails: ['alias@example.com'],
        email_addresses: %w[primary@example.com alias@example.com],
        additional_phones: ['+15557654321'],
        phone_numbers: %w[+15551234567 +15557654321]
      )
    end

    it 'includes contact point arrays in webhook data' do
      contact = create(:contact, account: account, email: 'primary@example.com', phone_number: '+15551234567')
      create(:contact_email, contact: contact, account: account, email: 'alias@example.com')
      create(:contact_phone, contact: contact, account: account, phone_number: '+15557654321')

      expect(contact.webhook_data).to include(
        additional_emails: ['alias@example.com'],
        email_addresses: %w[primary@example.com alias@example.com],
        additional_phones: ['+15557654321'],
        phone_numbers: %w[+15551234567 +15557654321]
      )
    end

    it 'dispatches destroyed contact event data with contact point arrays' do
      allow(Rails.configuration.dispatcher).to receive(:dispatch)
      contact = create(:contact, account: account, email: 'primary@example.com', phone_number: '+15551234567')
      create(:contact_email, contact: contact, account: account, email: 'alias@example.com')
      create(:contact_phone, contact: contact, account: account, phone_number: '+15557654321')

      contact.destroy!

      expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
        Events::Types::CONTACT_DELETED,
        kind_of(ActiveSupport::TimeWithZone),
        contact_data: hash_including(
          additional_emails: ['alias@example.com'],
          email_addresses: %w[primary@example.com alias@example.com],
          additional_phones: ['+15557654321'],
          phone_numbers: %w[+15551234567 +15557654321]
        )
      )
    end
  end

  context 'when city and country code passed in additional attributes' do
    it 'updates location and country code' do
      contact = create(:contact, additional_attributes: { city: 'New York', country: 'US' })
      expect(contact.location).to eq 'New York'
      expect(contact.country_code).to eq 'US'
    end
  end

  context 'when a contact is created' do
    it 'has contact type "visitor" by default' do
      contact = create(:contact)
      expect(contact.contact_type).to eq 'visitor'
    end

    it 'has contact type "lead" when email is present' do
      contact = create(:contact, email: 'test@test.com')
      expect(contact.contact_type).to eq 'lead'
    end

    it 'has contact type "lead" when contacted through a social channel' do
      contact = create(:contact, additional_attributes: { social_facebook_user_id: '123' })
      expect(contact.contact_type).to eq 'lead'
    end
  end

  describe '.resolved_contacts' do
    let(:account) { create(:account) }

    context 'when crm_v2 feature flag is disabled' do
      it 'returns contacts with email, phone_number, or identifier using feature flag value' do
        # Create contacts with different attributes
        contact_with_email = create(:contact, account: account, email: 'test@example.com', name: 'John Doe')
        contact_with_phone = create(:contact, account: account, phone_number: '+1234567890', name: 'Jane Smith')
        contact_with_identifier = create(:contact, account: account, identifier: 'user123', name: 'Bob Wilson')
        contact_with_additional_email = create(:contact, account: account, email: nil, phone_number: nil, identifier: nil)
        contact_with_additional_phone = create(:contact, account: account, email: nil, phone_number: nil, identifier: nil)
        create(:contact_email, contact: contact_with_additional_email, account: account, email: 'alias@example.com')
        create(:contact_phone, contact: contact_with_additional_phone, account: account, phone_number: '+15557654321')
        contact_without_details = create(:contact, account: account, name: 'Alice Johnson', email: nil, phone_number: nil, identifier: nil)

        resolved = account.contacts.resolved_contacts(use_crm_v2: false)

        expect(resolved).to include(
          contact_with_email,
          contact_with_phone,
          contact_with_identifier,
          contact_with_additional_email,
          contact_with_additional_phone
        )
        expect(resolved).not_to include(contact_without_details)
      end
    end

    context 'when crm_v2 feature flag is enabled' do
      it 'returns only contacts with contact_type lead' do
        # Contact with email and phone - should be marked as lead
        contact_with_details = create(:contact, account: account, email: 'customer@example.com', phone_number: '+1234567890', name: 'Customer One')
        expect(contact_with_details.contact_type).to eq('lead')

        # Contact without email/phone - should be marked as visitor
        contact_without_details = create(:contact, account: account, name: 'Lead', email: nil, phone_number: nil)
        expect(contact_without_details.contact_type).to eq('visitor')

        # Force set contact_type to lead for testing
        contact_without_details.update!(contact_type: 'lead')

        resolved = account.contacts.resolved_contacts(use_crm_v2: true)

        expect(resolved).to include(contact_with_details)
        expect(resolved).to include(contact_without_details)
      end

      it 'includes all lead contacts regardless of email/phone presence' do
        # Create a lead contact with only name
        lead_contact = create(:contact, account: account, name: 'Test Lead')
        lead_contact.update!(contact_type: 'lead')

        # Create a customer contact
        customer_contact = create(:contact, account: account, email: 'customer@test.com')
        customer_contact.update!(contact_type: 'customer')

        # Create a visitor contact
        visitor_contact = create(:contact, account: account, name: 'Visitor')
        expect(visitor_contact.contact_type).to eq('visitor')

        resolved = account.contacts.resolved_contacts(use_crm_v2: true)

        expect(resolved).to include(lead_contact)
        expect(resolved).not_to include(customer_contact)
        expect(resolved).not_to include(visitor_contact)
      end

      it 'returns contacts with email, phone_number, or identifier when explicitly passing use_crm_v2: false' do
        # Even though feature flag is enabled, we're explicitly passing false
        contact_with_email = create(:contact, account: account, email: 'test@example.com', name: 'John Doe')
        contact_with_phone = create(:contact, account: account, phone_number: '+1234567890', name: 'Jane Smith')
        contact_without_details = create(:contact, account: account, name: 'Alice Johnson', email: nil, phone_number: nil, identifier: nil)

        resolved = account.contacts.resolved_contacts(use_crm_v2: false)

        # Should use the old logic despite feature flag being enabled
        expect(resolved).to include(contact_with_email, contact_with_phone)
        expect(resolved).not_to include(contact_without_details)
      end
    end

    context 'with mixed contact types' do
      it 'correctly filters based on use_crm_v2 parameter regardless of feature flag' do
        # Create different types of contacts
        visitor_contact = create(:contact, account: account, name: 'Visitor')
        lead_with_email = create(:contact, account: account, email: 'lead@example.com', name: 'Lead')
        lead_without_email = create(:contact, account: account, name: 'Lead Only')
        lead_without_email.update!(contact_type: 'lead')
        customer_contact = create(:contact, account: account, email: 'customer@example.com', name: 'Customer')
        customer_contact.update!(contact_type: 'customer')

        # Test with use_crm_v2: false
        resolved_old = account.contacts.resolved_contacts(use_crm_v2: false)
        expect(resolved_old).to include(lead_with_email, customer_contact)
        expect(resolved_old).not_to include(visitor_contact, lead_without_email)

        # Test with use_crm_v2: true
        resolved_new = account.contacts.resolved_contacts(use_crm_v2: true)
        expect(resolved_new).to include(lead_with_email, lead_without_email)
        expect(resolved_new).not_to include(visitor_contact, customer_contact)
      end
    end
  end
end
