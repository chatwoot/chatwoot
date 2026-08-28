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

  it 'preserves a deferred terminal status from later progress callbacks' do
    described_class.persist_pending_status!(call, status: 'completed', duration: 12, timestamp: 100)
    described_class.persist_pending_status!(call, status: 'in_progress', duration: nil, timestamp: 90)

    expect(call.reload.meta['agent_termination_pending_status']).to eq(
      'status' => 'completed',
      'duration' => 12,
      'timestamp' => 100
    )
  end

  it 'retains and independently consumes every pending agent participant leave' do
    suppressions = %w[CA_OLD_TAB CA_NEW_TAB].map { |sid| described_class.suppress_local_disconnect!(call, sid) }
    expect(suppressions).to all(be true)

    call.reload
    expect(call.meta['agent_disconnect_suppress_call_sid']).to contain_exactly('CA_OLD_TAB', 'CA_NEW_TAB')

    expect(described_class.consume_local_disconnect!(call, 'CA_OLD_TAB')).to be true
    expect(call.reload.meta['agent_disconnect_suppress_call_sid']).to eq(['CA_NEW_TAB'])
    expect(described_class.consume_local_disconnect!(call, 'CA_OLD_TAB')).to be false
    expect(described_class.consume_local_disconnect!(call, 'CA_NEW_TAB')).to be true
    expect(call.reload.meta['agent_disconnect_suppress_call_sid']).to be_nil
  end

  it 'accepts a legacy single pending participant sid while consuming it' do
    call.update!(meta: call.meta.merge('agent_disconnect_suppress_call_sid' => 'CA_LEGACY'))

    expect(described_class.consume_local_disconnect!(call, 'CA_LEGACY')).to be true
    expect(call.reload.meta['agent_disconnect_suppress_call_sid']).to be_nil
  end

  it 'does not create disconnect suppression without an initiating participant sid' do
    expect(described_class.suppress_local_disconnect!(call, nil)).to be false
  end
end
