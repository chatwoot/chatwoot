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
end
