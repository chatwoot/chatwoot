# spec/services/contacts/sync_attributes_spec.rb

require 'rails_helper'

RSpec.describe Contacts::SyncAttributes do
  describe '#perform' do
    let(:contact) { create(:contact, additional_attributes: { 'city' => 'New York', 'country' => 'US' }) }

    context 'when a verified value changes without a trusted source' do
      it 'clears the mark, so a write that skips callbacks can store it' do
        contact.assign_verified_attributes({ name: 'Priya', email: 'priya@example.com' }, source: 'jwt')
        contact.save!

        contact.email = 'someone.else@example.com'
        described_class.new(contact).perform

        expect(contact.changes['verified_attributes']).to eq([{ 'name' => 'jwt', 'email' => 'jwt' }, { 'name' => 'jwt' }])
      end
    end

    context 'when contact has neither email/phone number nor social details' do
      it 'does not change contact type' do
        described_class.new(contact).perform
        expect(contact.reload.contact_type).to eq('visitor')
      end
    end

    context 'when contact has email or phone number' do
      it 'sets contact type to lead' do
        contact.email = 'test@test.com'
        contact.save
        described_class.new(contact).perform

        expect(contact.reload.contact_type).to eq('lead')
      end
    end

    context 'when contact has an identifier' do
      it 'sets contact type to lead' do
        contact.identifier = 'user-123'
        contact.save
        described_class.new(contact).perform

        expect(contact.reload.contact_type).to eq('lead')
      end
    end

    context 'when contact has social details' do
      it 'sets contact type to lead' do
        contact.additional_attributes['social_facebook_user_id'] = '123456789'
        contact.save
        described_class.new(contact).perform

        expect(contact.reload.contact_type).to eq('lead')
      end
    end

    context 'when location and country code are updated from additional attributes' do
      it 'updates location and country code' do
        described_class.new(contact).perform

        # Expect location and country code to be updated
        expect(contact.reload.location).to eq('New York')
        expect(contact.reload.country_code).to eq('US')
      end
    end
  end
end
