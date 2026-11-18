require 'rails_helper'

RSpec.describe Webhook do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:account_id) }
  end

  describe 'inbox ownership' do
    let(:account) { create(:account) }

    it 'rejects a nonexistent inbox ID' do
      missing_inbox_id = create(:inbox, account: account).id + 1
      record = build(:webhook, account: account, inbox_id: missing_inbox_id)

      expect(record).not_to be_valid
      expect(record.errors[:inbox_id]).to include('must belong to the same account as the webhook')
    end

    it 'allows an inbox belonging to the same account' do
      inbox = create(:inbox, account: account)
      record = build(:webhook, account: account, inbox: inbox)

      expect(record).to be_valid
    end

    it 'rejects an inbox belonging to another account' do
      record = build(:webhook, account: account, inbox: create(:inbox))

      expect(record).not_to be_valid
      expect(record.errors[:inbox_id]).to include('must belong to the same account as the webhook')
    end

    it 'allows account-wide webhooks without an inbox' do
      expect(build(:webhook, account: account, inbox: nil)).to be_valid
    end

    it 'rejects reassignment to a foreign inbox on update' do
      record = create(:webhook, account: account, inbox: create(:inbox, account: account))
      original_inbox_id = record.inbox_id

      expect(record.update(inbox: create(:inbox))).to be false
      expect(record.reload.inbox_id).to eq(original_inbox_id)
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
