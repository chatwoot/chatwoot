require 'rails_helper'

RSpec.describe Migration::SyncTelegramBusinessConfigChannelJob do
  it 'raises so Sidekiq retries a failed channel refresh independently' do
    channel = instance_double(Channel::Telegram, id: 30, refresh_business_config!: false)

    allow(Channel::Telegram).to receive(:find_by).with(id: 30).and_return(channel)

    expect { described_class.perform_now(30) }
      .to raise_error(CustomExceptions::TelegramBusinessConfigRefreshFailed, 'Telegram Business config refresh failed for channel ID: 30')
  end

  it 'finishes when the channel refresh succeeds' do
    channel = instance_double(Channel::Telegram, id: 30, refresh_business_config!: true)

    allow(Channel::Telegram).to receive(:find_by).with(id: 30).and_return(channel)

    expect { described_class.perform_now(30) }.not_to raise_error
  end
end
