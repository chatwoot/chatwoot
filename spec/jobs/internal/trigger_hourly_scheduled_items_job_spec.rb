require 'rails_helper'

RSpec.describe Internal::TriggerHourlyScheduledItemsJob do
  before do
    allow(Captain::Documents::ScheduleSyncsJob).to receive(:perform_later)
  end

  it 'enqueues enterprise Captain document auto-sync every six hours' do
    travel_to Time.zone.parse('2026-05-25 06:00:00 UTC') do
      described_class.perform_now
    end

    expect(Captain::Documents::ScheduleSyncsJob).to have_received(:perform_later).with('enterprise')
  end

  it 'does not enqueue enterprise Captain document auto-sync before the poll cadence' do
    travel_to Time.zone.parse('2026-05-25 07:00:00 UTC') do
      described_class.perform_now
    end

    expect(Captain::Documents::ScheduleSyncsJob).not_to have_received(:perform_later)
  end
end
