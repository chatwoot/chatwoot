require 'rails_helper'

describe Integrations::MutodayFaqReply::Telemetry do
  let(:account) { create(:account) }
  let(:logged) { [] }

  before do
    allow(Rails.logger).to receive(:info) { |line| logged << line.to_s }
    allow(Rails.logger).to receive(:warn) { |line| logged << line.to_s }
    allow(Rails.logger).to receive(:error) { |line| logged << line.to_s }
  end

  describe '.log' do
    it 'writes one tagged line in a fixed field order' do
      described_class.log(outcome: 'replied', route: 'model', mode: 'live', shadow: false,
                          conversation_id: 48_231, inbox_id: 7, contact_id: 9912,
                          result: 'matched', faq_id: 'contact_hours', confidence: 0.91, latency_ms: 742)

      expect(logged.size).to eq(1)
      expect(logged.first).to eq(
        '[mutoday_faq_reply] outcome=replied route=model result=matched mode=live shadow=false ' \
        'conversation_id=48231 inbox_id=7 contact_id=9912 faq_id=contact_hours confidence=0.91 latency_ms=742'
      )
    end

    it 'omits fields that were not supplied' do
      described_class.log(outcome: 'skipped', guard: 'already_answered', conversation_id: 1, inbox_id: 2)

      expect(logged.first).to eq('[mutoday_faq_reply] outcome=skipped guard=already_answered conversation_id=1 inbox_id=2')
    end

    it 'keeps shadow=false rather than dropping it as blank' do
      described_class.log(outcome: 'replied', shadow: false, conversation_id: 1)

      expect(logged.first).to include('shadow=false')
    end
  end

  # The privacy rule, enforced by the shape of the method rather than by review.
  describe 'the privacy rule' do
    it 'drops any field it does not know, so no customer text can reach a log line' do
      described_class.log(outcome: 'replied', conversation_id: 1,
                          content: 'อยากส่งข่าวประชาสัมพันธ์ต้องทำยังไง',
                          contact_name: 'สมชาย', source_id: 'U1234567890abcdef')

      line = logged.find { |entry| entry.include?('outcome=replied') }
      expect(line).not_to include('อยากส่งข่าวประชาสัมพันธ์ต้องทำยังไง', 'สมชาย', 'U1234567890abcdef')
      expect(line).to eq('[mutoday_faq_reply] outcome=replied conversation_id=1')
    end

    it 'names the dropped keys so a typo is visible, without printing their values' do
      described_class.log(outcome: 'replied', conversation_id: 1, content: 'ความลับ')

      warning = logged.find { |entry| entry.include?('dropped_fields') }
      expect(warning).to include('dropped_fields=content')
      expect(warning).not_to include('ความลับ')
    end

    it 'has no field name that could plausibly carry message text' do
      expect(described_class::FIELDS).not_to include(:content, :text, :body, :answer, :message, :source_id, :name)
    end
  end

  describe 'the closed sets' do
    it 'lists every outcome the feature can produce' do
      expect(described_class::OUTCOMES).to eq(%w[replied skipped refused_rate_limit misconfigured failed])
    end

    it 'lists exactly the guards the eligibility gate can return' do
      gate_source = Rails.root.join('lib/integrations/mutoday_faq_reply/eligibility.rb').read
      guards_in_use = gate_source.scan(/(?:skipped|misconfigured)\('([a-z_]+)'\)/).flatten
      guards_in_use += gate_source.scan(/'(already_answered|foreign_template)'/).flatten

      expect(guards_in_use.uniq.sort).to eq(described_class::GUARDS.sort)
    end

    it 'marks an out-of-set outcome rather than letting it pass as valid' do
      described_class.log(outcome: 'something_new', conversation_id: 1)

      expect(logged.first).to include('outcome=unknown(something_new)')
    end

    it 'marks an out-of-set guard the same way' do
      described_class.log(outcome: 'skipped', guard: 'invented', conversation_id: 1)

      expect(logged.first).to include('guard=unknown(invented)')
    end
  end

  describe '.alert' do
    let(:error) { Integrations::MutodayFaqReply::CircuitBreakerTripped.new('inbox_hour') }
    let(:tracker) { instance_double(ChatwootExceptionTracker, capture_exception: true) }

    before { allow(ChatwootExceptionTracker).to receive(:new).and_return(tracker) }

    after do
      %w[inbox_hour contact_hour model_timeout].each do |kind|
        Redis::Alfred.delete(format(described_class::ALERT_KEY, kind: kind))
      end
    end

    it 'captures the first alert of a kind' do
      described_class.alert(error, account: account, kind: 'inbox_hour')

      expect(tracker).to have_received(:capture_exception).once
    end

    it 'swallows the next one of the same kind within the window' do
      3.times { described_class.alert(error, account: account, kind: 'inbox_hour') }

      expect(tracker).to have_received(:capture_exception).once
    end

    it 'keys the dedup slot per kind, so one noisy kind cannot swallow another first alert' do
      described_class.alert(error, account: account, kind: 'inbox_hour')
      described_class.alert(error, account: account, kind: 'contact_hour')
      described_class.alert(error, account: account, kind: 'model_timeout')

      expect(tracker).to have_received(:capture_exception).exactly(3).times
    end

    it 'sets the slot with a TTL so the alert comes back after the window' do
      described_class.alert(error, account: account, kind: 'inbox_hour')

      expect(Redis::Alfred.ttl(format(described_class::ALERT_KEY, kind: 'inbox_hour'))).to be_positive
    end

    it 'never dedups when no kind is given — an auth or config failure is always ours to fix' do
      3.times { described_class.alert(error, account: account) }

      expect(tracker).to have_received(:capture_exception).exactly(3).times
    end
  end

  describe 'it never raises into the reply path' do
    it 'survives a logger that blows up' do
      allow(Rails.logger).to receive(:info).and_raise(IOError, 'log device closed')

      expect { described_class.log(outcome: 'replied', conversation_id: 1) }.not_to raise_error
    end

    it 'survives Sentry blowing up inside capture' do
      tracker = instance_double(ChatwootExceptionTracker)
      allow(ChatwootExceptionTracker).to receive(:new).and_return(tracker)
      allow(tracker).to receive(:capture_exception).and_raise(StandardError, 'sentry is down')

      expect { described_class.alert(StandardError.new('x'), account: account) }.not_to raise_error
    end

    it 'survives Redis being unreachable while claiming a dedup slot' do
      allow(Redis::Alfred).to receive(:set).and_raise(Redis::CannotConnectError, 'no connection')

      expect { described_class.alert(StandardError.new('x'), account: account, kind: 'inbox_hour') }.not_to raise_error
    end

    it 'survives a field whose to_s raises' do
      exploding = Class.new { def to_s = raise('boom') }.new

      expect { described_class.log(outcome: 'replied', faq_id: exploding) }.not_to raise_error
    end
  end
end
