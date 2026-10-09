# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voice::CallStatus::Manager do
  let(:call) { create(:call) }

  it 'keeps a terminal status that was persisted after the call was loaded' do
    stale_call = Call.find(call.id)
    call.update!(status: 'rejected', end_reason: 'agent_rejected')

    described_class.new(call: stale_call).process_status_update('completed')

    expect(call.reload).to have_attributes(status: 'rejected', end_reason: 'agent_rejected')
  end

  it 'keeps an answered call live when a late ringing status arrives' do
    call.update!(status: 'in_progress')

    described_class.new(call: call).process_status_update('ringing')

    expect(call.reload.status).to eq('in_progress')
  end

  it 'leaves a ringing call to the ring timeout that is hanging it up' do
    call.update!(status: 'ringing', ring_state: { 'timing_out_at' => Time.zone.now.to_i })

    described_class.new(call: call).process_status_update('completed')

    expect(call.reload.status).to eq('ringing')
  end

  it 'applies the status once a timeout attempt has long expired' do
    call.update!(status: 'ringing', ring_state: { 'timing_out_at' => 10.minutes.ago.to_i })

    described_class.new(call: call).process_status_update('completed')

    expect(call.reload.status).to eq('completed')
  end
end
