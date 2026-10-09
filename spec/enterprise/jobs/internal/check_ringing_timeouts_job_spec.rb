require 'rails_helper'

RSpec.describe Internal::CheckRingingTimeoutsJob do
  it 'checks the ringing timeouts on Enterprise' do
    allow(ChatwootApp).to receive(:enterprise?).and_return(true)
    allow(Voice::RingingTimeoutJob).to receive(:perform_now)

    described_class.perform_now

    expect(Voice::RingingTimeoutJob).to have_received(:perform_now)
  end

  it 'does nothing outside Enterprise' do
    allow(ChatwootApp).to receive(:enterprise?).and_return(false)
    allow(Voice::RingingTimeoutJob).to receive(:perform_now)

    described_class.perform_now

    expect(Voice::RingingTimeoutJob).not_to have_received(:perform_now)
  end
end
