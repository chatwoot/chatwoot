require 'rails_helper'

RSpec.describe Webhook do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:account_id) }
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
