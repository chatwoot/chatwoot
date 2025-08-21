# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channel::Voice do
  let(:channel) { create(:channel_voice) }

  it 'has a valid factory' do
    expect(channel).to be_valid
  end

  describe 'validations' do
    it 'validates presence of provider_config' do
      channel.provider_config = nil
      expect(channel).not_to be_valid
      expect(channel.errors[:provider_config]).to include("can't be blank")
    end

    it 'validates presence of account_sid in provider_config' do
      channel.provider_config = { auth_token: 'token' }
      expect(channel).not_to be_valid
      expect(channel.errors[:provider_config]).to include('account_sid is required for Twilio provider')
    end

    it 'validates presence of auth_token in provider_config' do
      channel.provider_config = { account_sid: 'sid' }
      expect(channel).not_to be_valid
      expect(channel.errors[:provider_config]).to include('auth_token is required for Twilio provider')
    end

    it 'validates presence of api_key_sid in provider_config' do
      channel.provider_config = { account_sid: 'sid', auth_token: 'token' }
      expect(channel).not_to be_valid
      expect(channel.errors[:provider_config]).to include('api_key_sid is required for Twilio provider')
    end

    it 'validates presence of api_key_secret in provider_config' do
      channel.provider_config = { account_sid: 'sid', auth_token: 'token', api_key_sid: 'key' }
      expect(channel).not_to be_valid
      expect(channel.errors[:provider_config]).to include('api_key_secret is required for Twilio provider')
    end

    it 'is valid with all required provider_config fields' do
      channel.provider_config = {
        account_sid: 'test_sid',
        auth_token: 'test_token',
        api_key_sid: 'test_key',
        api_key_secret: 'test_secret'
      }
      expect(channel).to be_valid
    end
  end

  describe '#name' do
    it 'returns Voice with phone number' do
      expect(channel.name).to include('Voice')
      expect(channel.name).to include(channel.phone_number)
    end
  end
end
