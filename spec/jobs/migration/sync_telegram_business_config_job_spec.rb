require 'rails_helper'

RSpec.describe Migration::SyncTelegramBusinessConfigJob do
  it 'refreshes Telegram Business capability for every existing channel' do
    channel = instance_double(Channel::Telegram)

    allow(Channel::Telegram).to receive(:find_each).and_yield(channel)
    expect(channel).to receive(:refresh_business_config!)

    described_class.perform_now
  end
end
