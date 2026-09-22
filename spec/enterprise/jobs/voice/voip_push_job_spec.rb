# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voice::VoipPushJob do
  let(:call) { create(:call) }
  let(:service) { instance_double(Voice::VoipPushService, perform: nil) }

  before do
    allow(Voice::VoipPushService).to receive(:new).and_return(service)
  end

  it 'is enqueued on the critical queue' do
    expect(described_class.new.queue_name).to eq('critical')
  end

  it 'hands the action to the push service' do
    described_class.perform_now(call.id, 'ring')

    expect(Voice::VoipPushService).to have_received(:new).with(call: call)
    expect(service).to have_received(:perform).with('ring')
  end

  it 'ignores a call that no longer exists' do
    described_class.perform_now(call.id + 1000, 'ring')

    expect(Voice::VoipPushService).not_to have_received(:new)
  end
end
