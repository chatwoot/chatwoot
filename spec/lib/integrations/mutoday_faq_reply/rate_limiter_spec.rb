require 'rails_helper'

describe Integrations::MutodayFaqReply::RateLimiter do
  let(:account) { create(:account) }
  let(:hook) { create(:integrations_hook, :mutoday_faq_reply, account: account) }
  let(:inbox) { hook.inbox }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let(:conversation) do
    create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox)
  end
  let(:limiter) { described_class.new(conversation: conversation) }

  let(:hour) { Time.current.strftime('%Y%m%d%H') }
  let(:day) { Time.current.strftime('%Y%m%d') }
  let(:contact_key) { format(described_class::CONTACT_HOUR_KEY, contact_id: contact.id, bucket: hour) }
  let(:inbox_hour_key) { format(described_class::INBOX_HOUR_KEY, inbox_id: inbox.id, bucket: hour) }
  let(:inbox_day_key) { format(described_class::INBOX_DAY_KEY, inbox_id: inbox.id, bucket: day) }

  after { [contact_key, inbox_hour_key, inbox_day_key].each { |key| Redis::Alfred.delete(key) } }

  describe 'the limits' do
    it 'allows 12 replies per contact per hour, not 3' do
      expect(described_class::LIMITS[:contact_hour][:limit]).to eq(12)
    end

    it 'allows 60 per inbox hour and 500 per inbox day' do
      expect(described_class::LIMITS[:inbox_hour][:limit]).to eq(60)
      expect(described_class::LIMITS[:inbox_day][:limit]).to eq(500)
    end
  end

  describe '#reserve' do
    it 'reserves while every scope has capacity' do
      expect(limiter.reserve).to be_nil
    end

    it 'counts one against each scope per reservation' do
      3.times { limiter.reserve }

      expect(Redis::Alfred.get(contact_key)).to eq('3')
      expect(Redis::Alfred.get(inbox_hour_key)).to eq('3')
      expect(Redis::Alfred.get(inbox_day_key)).to eq('3')
    end

    it 'sets a TTL on the first increment' do
      limiter.reserve

      expect(Redis::Alfred.ttl(contact_key)).to be_positive
      expect(Redis::Alfred.ttl(inbox_hour_key)).to be_positive
      expect(Redis::Alfred.ttl(inbox_day_key)).to be_positive
    end

    it 'allows exactly the contact limit and refuses the next one' do
      12.times { expect(limiter.reserve).to be_nil }

      expect(limiter.reserve).to eq({ outcome: 'refused_rate_limit', scope: 'contact_hour', limit: 12 })
    end

    it 'does not consume budget on a refusal, so a retry cannot dig the hole deeper' do
      Redis::Alfred.set(contact_key, '12', ex: 3600)

      3.times { expect(limiter.reserve).to eq({ outcome: 'refused_rate_limit', scope: 'contact_hour', limit: 12 }) }

      expect(Redis::Alfred.get(contact_key)).to eq('12')
    end

    it 'names the inbox hour scope when that is the one that is full' do
      Redis::Alfred.set(inbox_hour_key, '60', ex: 3600)

      expect(limiter.reserve).to eq({ outcome: 'refused_rate_limit', scope: 'inbox_hour', limit: 60 })
    end

    it 'names the inbox day scope when that is the one that is full' do
      Redis::Alfred.set(inbox_day_key, '500', ex: 3600)

      expect(limiter.reserve).to eq({ outcome: 'refused_rate_limit', scope: 'inbox_day', limit: 500 })
    end

    it 'keeps each contact on their own budget' do
      other_contact = create(:contact, account: account)
      other_contact_inbox = create(:contact_inbox, contact: other_contact, inbox: inbox)
      other_conversation = create(:conversation, account: account, inbox: inbox,
                                                 contact: other_contact, contact_inbox: other_contact_inbox)
      Redis::Alfred.set(contact_key, '12', ex: 3600)

      expect(described_class.new(conversation: other_conversation).reserve).to be_nil
      Redis::Alfred.delete(format(described_class::CONTACT_HOUR_KEY, contact_id: other_contact.id, bucket: hour))
    end
  end

  # C3 — a WATCH abort is ordinary concurrency on a shared key, not a breach. Conflating
  # the two would page Sentry and withhold a customer's reply whenever two workers
  # happened to touch the same counter.
  describe 'contention' do
    it 'lets two reservations through while capacity remains' do
      results = []
      threads = Array.new(2) do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection { results << limiter.reserve }
        end
      end
      threads.each(&:join)

      expect(results).to eq([nil, nil])
      expect(Redis::Alfred.get(contact_key)).to eq('2')
    end

    it 'retries a contended reservation and does not report it as a limit' do
      redis = instance_double(Redis)
      call_count = 0
      allow(Redis::Alfred).to receive(:with).and_yield(redis)
      allow(redis).to receive(:unwatch)
      allow(redis).to receive(:get).and_return('0')
      allow(redis).to receive(:multi) do
        call_count += 1
        call_count == 1 ? nil : [1, true]
      end
      allow(redis).to receive(:watch) { |_key, &block| block.call }

      expect(limiter.reserve).to be_nil
      expect(call_count).to be >= 2
    end

    it 'gives up after three contended attempts and lets the reply through, logging it' do
      redis = instance_double(Redis)
      allow(Redis::Alfred).to receive(:with).and_yield(redis)
      allow(redis).to receive(:unwatch)
      allow(redis).to receive(:get).and_return('0')
      allow(redis).to receive(:multi).and_return(nil)
      allow(redis).to receive(:watch) { |_key, &block| block.call }
      allow(Rails.logger).to receive(:info)

      expect(limiter.reserve).to be_nil
      expect(Rails.logger).to have_received(:info).with(/outcome=rate_limit_contended scope=contact_hour/)
    end

    it 'still refuses a genuine breach rather than treating it as contention' do
      redis = instance_double(Redis)
      allow(Redis::Alfred).to receive(:with).and_yield(redis)
      allow(redis).to receive(:unwatch)
      allow(redis).to receive(:get).and_return('12')
      allow(redis).to receive(:watch) { |_key, &block| block.call }

      expect(limiter.reserve).to eq({ outcome: 'refused_rate_limit', scope: 'contact_hour', limit: 12 })
    end
  end

  describe 'C14 — Redis is unreachable' do
    it 'fails closed with stage=redis' do
      allow(Redis::Alfred).to receive(:with).and_raise(Redis::CannotConnectError, 'no connection')

      result = limiter.reserve

      expect(result[:outcome]).to eq('failed')
      expect(result[:stage]).to eq('redis')
      expect(result[:error]).to eq('Redis::CannotConnectError')
    end
  end

  describe 'the bucket keys' do
    it 'buckets by app-zone hour and day' do
      expect(contact_key).to end_with(Time.current.strftime('%Y%m%d%H'))
      expect(inbox_day_key).to end_with(Time.current.strftime('%Y%m%d'))
    end

    it 'moves to a fresh bucket in the next hour' do
      limiter.reserve

      travel_to(1.hour.from_now) do
        next_key = format(described_class::CONTACT_HOUR_KEY, contact_id: contact.id, bucket: Time.current.strftime('%Y%m%d%H'))
        expect(Redis::Alfred.get(next_key)).to be_nil
        expect(limiter.reserve).to be_nil
        Redis::Alfred.delete(next_key)
        Redis::Alfred.delete(format(described_class::INBOX_HOUR_KEY, inbox_id: inbox.id, bucket: Time.current.strftime('%Y%m%d%H')))
      end
    end
  end
end
