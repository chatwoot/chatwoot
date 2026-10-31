require 'rails_helper'

RSpec.describe Webhook do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:account_id) }
  end

  describe 'url format validation' do
    let(:account) { create(:account) }

    it 'accepts public https urls' do
      webhook = build(:webhook, account: account, url: 'https://example.com/webhook')
      expect(webhook).to be_valid
    end

    it 'accepts local IPv4 addresses with ports' do
      webhook = build(:webhook, account: account, url: 'http://192.168.1.10:8000/webhook')
      expect(webhook).to be_valid
    end

    it 'accepts localhost urls' do
      webhook = build(:webhook, account: account, url: 'http://localhost:3000/webhook')
      expect(webhook).to be_valid
    end

    it 'accepts IPv6 addresses with ports' do
      webhook = build(:webhook, account: account, url: 'http://[::1]:3000/webhook')
      expect(webhook).to be_valid
    end

    it 'rejects non-http(s) urls' do
      webhook = build(:webhook, account: account, url: 'javascript:alert(1)')
      expect(webhook).not_to be_valid
      expect(webhook.errors[:url]).to be_present
    end

    it 'rejects malformed urls' do
      webhook = build(:webhook, account: account, url: 'not a url')
      expect(webhook).not_to be_valid
      expect(webhook.errors[:url]).to be_present
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
  end

  describe 'secret token' do
    let!(:account) { create(:account) }

    it 'auto-generates a secret on create' do
      webhook = create(:webhook, account: account)
      expect(webhook.secret).to be_present
    end

    it 'does not regenerate the secret on update' do
      webhook = create(:webhook, account: account)
      original_secret = webhook.secret
      webhook.update!(url: "#{webhook.url}?updated=1")
      expect(webhook.reload.secret).to eq(original_secret)
    end
  end
end
