require 'rails_helper'

describe ContactIdentifyAction do
  subject(:contact_identify) { described_class.new(contact: contact, params: params).perform }

  let!(:account) { create(:account) }
  let(:custom_attributes) { { test: 'test', test1: 'test1' } }
  let!(:contact) { create(:contact, account: account, custom_attributes: custom_attributes) }
  let(:params) do
    { name: 'test', identifier: 'test_id', additional_attributes: { location: 'Bengaulru', company_name: 'Meta' },
      custom_attributes: { test: 'new test', test2: 'test2' } }
  end

  describe '#perform' do
    it 'updates the contact' do
      expect(Avatar::AvatarFromUrlJob).not_to receive(:perform_later).with(contact, params[:avatar_url])
      contact_identify
      expect(contact.reload.name).to eq 'test'
      # custom attributes are merged properly without overwriting existing ones
      expect(contact.custom_attributes).to eq({ 'test' => 'new test', 'test1' => 'test1', 'test2' => 'test2' })
      expect(contact.additional_attributes).to eq({ 'company_name' => 'Meta', 'location' => 'Bengaulru' })
      expect(contact.reload.identifier).to eq 'test_id'
    end

    it 'will not call avatar job if avatar is already attached' do
      contact.avatar.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      expect(Avatar::AvatarFromUrlJob).not_to receive(:perform_later).with(contact, params[:avatar_url])
      contact_identify
    end

    it 'merge deeply nested additional attributes' do
      create(:contact, account: account, identifier: '', email: 'test@test.com',
                       additional_attributes: { location: 'Bengaulru', company_name: 'Meta', social_profiles: { linkedin: 'saras' } })
      params = { email: 'test@test.com', additional_attributes: { social_profiles: { twitter: 'saras' } } }
      result = described_class.new(contact: contact, params: params).perform
      expect(result.additional_attributes['social_profiles']).to eq({ 'linkedin' => 'saras', 'twitter' => 'saras' })
    end

    it 'enques avatar job when avatar url parameter is passed' do
      params = { name: 'test', avatar_url: 'https://chatwoot-assets.local/sample.png' }
      expect(Avatar::AvatarFromUrlJob).to receive(:perform_later).with(contact, params[:avatar_url]).once
      described_class.new(contact: contact, params: params).perform
    end

    context 'when contact with same identifier exists' do
      it 'merges the current contact to identified contact' do
        existing_identified_contact = create(:contact, account: account, identifier: 'test_id')
        result = contact_identify
        expect(result.id).to eq existing_identified_contact.id
        expect(result.name).to eq params[:name]
        expect { contact.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when contact with same email exists' do
      it 'merges the current contact to email contact' do
        existing_email_contact = create(:contact, account: account, email: 'test@test.com', name: 'old name')
        params = { name: 'new name', email: 'test@test.com' }
        result = described_class.new(contact: contact, params: params).perform
        expect(result.id).to eq existing_email_contact.id
        expect(result.name).to eq 'new name'
        expect { contact.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'will not merge the current contact to email contact if identifier of email contact is different' do
        existing_email_contact = create(:contact, account: account, identifier: '1', email: 'test@test.com')
        params = { identifier: '2', email: 'test@test.com' }
        result = described_class.new(contact: contact, params: params).perform
        expect(result.id).not_to eq existing_email_contact.id
        expect(result.identifier).to eq params[:identifier]
        expect(result.email).to be_nil
      end
    end

    context 'when contact with same phone_number exists' do
      it 'merges the current contact to phone_number contact' do
        existing_phone_number_contact = create(:contact, account: account, phone_number: '+919999888877')
        params = { phone_number: '+919999888877' }
        result = described_class.new(contact: contact, params: params).perform
        expect(result.id).to eq existing_phone_number_contact.id
        expect(result.name).to eq existing_phone_number_contact.name
        expect { contact.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'will not merge the current contact to phone contact if identifier of phone contact is different' do
        existing_phone_number_contact = create(:contact, account: account, identifier: '1', phone_number: '+919999888877')
        params = { identifier: '2', phone_number: '+919999888877' }
        result = described_class.new(contact: contact, params: params).perform
        expect(result.id).not_to eq existing_phone_number_contact.id
        expect(result.identifier).to eq params[:identifier]
        expect(result.email).to be_nil
      end

      it 'will not overide the phone contacts email when params contains different email' do
        existing_phone_number_contact = create(:contact, account: account, email: '1@test.com', phone_number: '+919999888877')
        params = { email: '2@test.com', phone_number: '+919999888877' }
        result = described_class.new(contact: contact, params: params).perform
        expect(result.id).not_to eq existing_phone_number_contact.id
        expect(result.email).to eq params[:email]
        expect(result.phone_number).to be_nil
      end
    end

    context 'when contacts with blank identifiers exist and identify action is called with blank identifier' do
      it 'updates the attributes of contact passed in to identify action' do
        create(:contact, account: account, identifier: '')
        params = { identifier: '', name: 'new name' }
        result = described_class.new(contact: contact, params: params).perform
        expect(result.id).to eq contact.id
        expect(result.name).to eq 'new name'
      end
    end

    context 'when retain_original_contact_name is set to true' do
      it 'will not update the name of the existing contact' do
        existing_email_contact = create(:contact, account: account, name: 'old name', email: 'test@test.com')
        params = { email: 'test@test.com', name: 'new name' }
        result = described_class.new(contact: contact, params: params, retain_original_contact_name: true).perform
        expect(result.id).to eq existing_email_contact.id
        expect(result.name).to eq 'old name'
        expect { contact.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when discard_invalid_attrs is set to false' do
      it 'will not update the name of the existing contact' do
        params = { email: 'blah blah blah', name: 'new name' }
        expect do
          described_class.new(contact: contact, params: params, retain_original_contact_name: true).perform
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when discard_invalid_attrs is set to true' do
      it 'will not update the name of the existing contact' do
        params = { phone_number: 'blahblah blah', name: 'new name' }
        described_class.new(contact: contact, params: params, discard_invalid_attrs: true).perform
        expect(contact.reload.name).to eq 'new name'
        expect(contact.phone_number).to be_nil
      end
    end
  end
end
