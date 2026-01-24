# frozen_string_literal: true

require 'rails_helper'

# CommMate: Unit tests for PreferencesController
# Tests verify controller logic for the public preferences feature
RSpec.describe Public::Api::V1::PreferencesController, type: :controller do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account, phone_number: '+1234567890', email: 'test@example.com') }
  let(:campaign_label) { create(:label, account: account, title: 'promotions', available_for_campaigns: true) }

  def generate_valid_token
    ContactPreferenceTokenService.generate_for_contact(contact)
  end

  def generate_expired_token
    payload = {
      contact_id: contact.id,
      account_id: account.id,
      exp: 1.day.ago.to_i,
      iat: 2.days.ago.to_i
    }
    JWT.encode(payload, Rails.application.secret_key_base, 'HS256')
  end

  describe '#contact_identifier_text' do
    it 'returns email and phone when both present' do
      result = controller.send(:contact_identifier_text, contact)
      expect(result).to include(contact.email)
      expect(result).to include(contact.phone_number)
      expect(result).to include('•')
    end

    it 'returns only email when phone is missing' do
      contact.update(phone_number: nil)
      result = controller.send(:contact_identifier_text, contact)
      expect(result).to include(contact.email)
      expect(result).not_to include('•')
    end

    it 'returns only phone when email is missing' do
      contact.update(email: nil)
      result = controller.send(:contact_identifier_text, contact)
      expect(result).to include(contact.phone_number)
      expect(result).not_to include('•')
    end

    it 'returns empty string when contact is nil' do
      result = controller.send(:contact_identifier_text, nil)
      expect(result).to eq('')
    end
  end

  describe '#find_campaign_label' do
    before do
      controller.instance_variable_set(:@account, account)
      campaign_label # create it
    end

    it 'finds label by ID' do
      result = controller.send(:find_campaign_label, campaign_label.id.to_s)
      expect(result).to eq(campaign_label)
    end

    it 'finds label by title' do
      result = controller.send(:find_campaign_label, campaign_label.title)
      expect(result).to eq(campaign_label)
    end

    it 'returns nil for non-existent label' do
      result = controller.send(:find_campaign_label, '999999')
      expect(result).to be_nil
    end

    it 'does not find non-campaign labels' do
      non_campaign = create(:label, account: account, title: 'internal', available_for_campaigns: false)
      result = controller.send(:find_campaign_label, non_campaign.title)
      expect(result).to be_nil
    end
  end

  describe '#error_status_for' do
    it 'returns :gone for expired tokens' do
      expect(controller.send(:error_status_for, :expired)).to eq(:gone)
    end

    it 'returns :gone for invalid tokens' do
      expect(controller.send(:error_status_for, :invalid)).to eq(:gone)
    end

    it 'returns :not_found for contact_not_found' do
      expect(controller.send(:error_status_for, :contact_not_found)).to eq(:not_found)
    end

    it 'returns :not_found for label_not_found' do
      expect(controller.send(:error_status_for, :label_not_found)).to eq(:not_found)
    end

    it 'returns :service_unavailable for account_unavailable' do
      expect(controller.send(:error_status_for, :account_unavailable)).to eq(:service_unavailable)
    end
  end

  describe 'locale detection' do
    describe '#extract_quality' do
      it 'extracts quality from q= parameter' do
        expect(controller.send(:extract_quality, 'q=0.8')).to eq(0.8)
      end

      it 'returns 1.0 for nil' do
        expect(controller.send(:extract_quality, nil)).to eq(1.0)
      end

      it 'returns 1.0 for invalid format' do
        expect(controller.send(:extract_quality, 'invalid')).to eq(1.0)
      end
    end
  end
end
