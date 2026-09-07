require 'rails_helper'

RSpec.describe Internal::TriggerDailyScheduledItemsJob do
  before do
    allow(ChatwootHub).to receive(:installation_identifier).and_return('test-installation-id')
    allow(Captain::Documents::ScheduleSyncsJob).to receive(:perform_later)
  end

  it 'enqueues enterprise Captain document auto-sync every day' do
    travel_to Time.zone.parse('2026-05-26 00:00:00 UTC') do
      described_class.perform_now
    end

    expect(Captain::Documents::ScheduleSyncsJob).to have_received(:perform_later).with('enterprise')
  end

  it 'enqueues business Captain document auto-sync weekly' do
    travel_to Time.zone.parse('2026-05-24 00:00:00 UTC') do
      described_class.perform_now
    end

    expect(Captain::Documents::ScheduleSyncsJob).to have_received(:perform_later).with('business')
  end

  it 'enqueues startup Captain document auto-sync monthly' do
    travel_to Time.zone.parse('2026-06-01 00:00:00 UTC') do
      described_class.perform_now
    end

    expect(Captain::Documents::ScheduleSyncsJob).to have_received(:perform_later).with('startups')
  end

  it 'does not enqueue business or startup Captain document auto-sync before their plan window' do
    travel_to Time.zone.parse('2026-05-25 00:00:00 UTC') do
      described_class.perform_now
    end

    expect(Captain::Documents::ScheduleSyncsJob).to have_received(:perform_later).with('enterprise')
    expect(Captain::Documents::ScheduleSyncsJob).not_to have_received(:perform_later).with('business')
    expect(Captain::Documents::ScheduleSyncsJob).not_to have_received(:perform_later).with('startups')
  end
end
