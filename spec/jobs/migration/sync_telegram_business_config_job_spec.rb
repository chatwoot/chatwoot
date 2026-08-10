require 'rails_helper'

RSpec.describe Migration::SyncTelegramBusinessConfigJob do
  before do
    stub_const("#{described_class}::BATCH_SIZE", 2)
  end

  it 'refreshes one batch and enqueues the next batch from the last processed channel' do
    first_channel = instance_double(Channel::Telegram, id: 10)
    second_channel = instance_double(Channel::Telegram, id: 20)
    remaining_channel = instance_double(Channel::Telegram, id: 30)
    scope = double

    allow(Channel::Telegram).to receive(:where).with('id > ?', 0).and_return(scope)
    allow(scope).to receive(:order).with(:id).and_return(scope)
    allow(scope).to receive(:limit).with(3).and_return(scope)
    allow(scope).to receive(:to_a).and_return([first_channel, second_channel, remaining_channel])
    allow(first_channel).to receive(:refresh_business_config!).and_return(true)
    allow(second_channel).to receive(:refresh_business_config!).and_return(true)
    allow(remaining_channel).to receive(:refresh_business_config!)

    expect { described_class.perform_now }
      .to have_enqueued_job(described_class).with(after_id: 20).on_queue('async_database_migration')

    expect(first_channel).to have_received(:refresh_business_config!)
    expect(second_channel).to have_received(:refresh_business_config!)
    expect(remaining_channel).not_to have_received(:refresh_business_config!)
  end

  it 'does not enqueue another job after the final batch' do
    channel = instance_double(Channel::Telegram, id: 30, refresh_business_config!: true)
    scope = double

    allow(Channel::Telegram).to receive(:where).with('id > ?', 20).and_return(scope)
    allow(scope).to receive(:order).with(:id).and_return(scope)
    allow(scope).to receive(:limit).with(3).and_return(scope)
    allow(scope).to receive(:to_a).and_return([channel])

    expect { described_class.perform_now(after_id: 20) }.not_to have_enqueued_job(described_class)
    expect(channel).to have_received(:refresh_business_config!)
  end

  it 'raises so the current batch is retried when a channel refresh fails' do
    channel = instance_double(Channel::Telegram, id: 30, refresh_business_config!: false)
    scope = double

    allow(Channel::Telegram).to receive(:where).with('id > ?', 20).and_return(scope)
    allow(scope).to receive(:order).with(:id).and_return(scope)
    allow(scope).to receive(:limit).with(3).and_return(scope)
    allow(scope).to receive(:to_a).and_return([channel])

    expect { described_class.perform_now(after_id: 20) }
      .to raise_error(described_class::RefreshFailed, 'Telegram Business config refresh failed for channel IDs: 30')
    expect(described_class).not_to have_been_enqueued
  end
end
