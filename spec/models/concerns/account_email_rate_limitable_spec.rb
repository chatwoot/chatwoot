require 'rails_helper'

RSpec.describe AccountEmailRateLimitable do
  let(:account) { create(:account) }

  describe '#email_rate_limit' do
    it 'returns account-level override when set' do
      account.update!(limits: { 'emails' => 50 })
      expect(account.email_rate_limit).to eq(50)
    end

    it 'returns global config when no account override' do
      InstallationConfig.where(name: 'ACCOUNT_EMAILS_LIMIT').first_or_create(value: 200)
      expect(account.email_rate_limit).to eq(200)
    end

    it 'returns account override over global config' do
      InstallationConfig.where(name: 'ACCOUNT_EMAILS_LIMIT').first_or_create(value: 200)
      account.update!(limits: { 'emails' => 50 })
      expect(account.email_rate_limit).to eq(50)
    end
  end

  describe '#within_email_rate_limit?' do
    before do
      allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
      account.update!(limits: { 'emails' => 2 })
    end

    it 'returns true when under limit' do
      expect(account).to be_within_email_rate_limit
    end

    it 'returns false when at limit' do
      2.times { account.increment_email_sent_count }
      expect(account).not_to be_within_email_rate_limit
    end

    context 'when self-hosted' do
      before do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)
        2.times { account.increment_email_sent_count }
      end

      it 'always returns true regardless of limit' do
        expect(account).to be_within_email_rate_limit
      end
    end

    context 'when chatwoot cloud' do
      before do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
        2.times { account.increment_email_sent_count }
      end

      it 'returns false when at limit' do
        expect(account).not_to be_within_email_rate_limit
      end
    end
  end

  describe '#increment_email_sent_count' do
    it 'increments the counter' do
      expect { account.increment_email_sent_count }.to change(account, :emails_sent_today).by(1)
    end

    it 'sets TTL on first increment' do
      key = format(Redis::Alfred::ACCOUNT_OUTBOUND_EMAIL_COUNT_KEY, account_id: account.id, date: Time.zone.today.to_s)
      allow(Redis::Alfred).to receive(:incr).and_return(1)
      allow(Redis::Alfred).to receive(:expire)

      account.increment_email_sent_count

      expect(Redis::Alfred).to have_received(:expire).with(key, AccountEmailRateLimitable::OUTBOUND_EMAIL_TTL)
    end

    it 'does not reset TTL on subsequent increments' do
      allow(Redis::Alfred).to receive(:incr).and_return(2)
      allow(Redis::Alfred).to receive(:expire)

      account.increment_email_sent_count

      expect(Redis::Alfred).not_to have_received(:expire)
    end
  end

  describe '#reserve_email_send_capacity' do
    context 'when chatwoot cloud' do
      before do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
        account.update!(limits: { 'emails' => 2 })
      end

      it 'atomically reserves capacity without exceeding the limit' do
        expect(account.reserve_email_send_capacity).to be true
        expect(account.reserve_email_send_capacity).to be true
        expect(account.reserve_email_send_capacity).to be false
        expect(account.emails_sent_today).to eq(2)
      end

      it 'does not partially reserve a batch that exceeds the remaining capacity' do
        expect(account.reserve_email_send_capacity(2)).to be true
        expect(account.reserve_email_send_capacity(2)).to be false
        expect(account.emails_sent_today).to eq(2)
      end

      it 'unwatches the counter when capacity is exhausted' do
        redis = instance_double(Redis)
        key = format(Redis::Alfred::ACCOUNT_OUTBOUND_EMAIL_COUNT_KEY, account_id: account.id, date: Time.zone.today.to_s)
        allow(Redis::Alfred).to receive(:with).and_yield(redis)
        allow(account).to receive(:emails_sent_today).and_return(2)
        allow(redis).to receive(:watch).with(key).and_yield
        allow(redis).to receive(:get).with(key).and_return('2')
        expect(redis).to receive(:unwatch)
        expect(redis).not_to receive(:multi)

        expect(account.reserve_email_send_capacity).to be false
      end
    end

    context 'when self-hosted' do
      before do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)
        account.update!(limits: { 'emails' => 1 })
      end

      it 'does not reserve or track email capacity' do
        expect(account.reserve_email_send_capacity(2)).to be true
        expect(account.emails_sent_today).to eq(0)
      end
    end
  end
end
