require 'rails_helper'

RSpec.describe Voice::CallTerminationGuard do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: channel.inbox) }
  let(:call) do
    create(:call, account: account, inbox: channel.inbox, conversation: conversation,
                  contact: conversation.contact, status: 'ringing')
  end

  it 'treats a freshly claimed guard as active' do
    now = Time.zone.now
    call.update!(meta: described_class.claim_meta(call, token: 'owner-token', now: now))

    expect(described_class.active?(call, now: now + 1.minute)).to be true
  end

  it 'expires and clears an abandoned guard after the TTL' do
    now = Time.zone.now
    call.update!(meta: described_class.claim_meta(call, token: 'owner-token', now: now - 3.minutes))

    call.with_lock { described_class.clear_stale!(call, now: now) }

    call.reload
    expect(described_class.active?(call, now: now)).to be false
    expect(call.meta['agent_termination_token']).to be_nil
    expect(call.meta['agent_termination_started_at']).to be_nil
  end

  it 'expires legacy token-only guards using the call update timestamp' do
    now = Time.zone.now
    call.update!(meta: call.meta.merge('agent_termination_token' => 'legacy-token'))
    call.update_column(:updated_at, now - 3.minutes) # rubocop:disable Rails/SkipsModelValidations
    call.reload

    expect(described_class.active?(call, now: now)).to be false
  end

  it 'suppresses and consumes only the matching agent participant leave' do
    described_class.track_agent_participant!(call, 'CA_AGENT_1')
    expect(described_class.suppress_local_disconnect!(call)).to be true

    expect(described_class.consume_local_disconnect!(call, 'CA_OTHER')).to be false
    expect(described_class.consume_local_disconnect!(call, 'CA_AGENT_1')).to be true
    expect(described_class.consume_local_disconnect!(call, 'CA_AGENT_1')).to be false
  end

  it 'does not create disconnect suppression when no agent participant sid is known' do
    expect(described_class.suppress_local_disconnect!(call)).to be false
  end
end
