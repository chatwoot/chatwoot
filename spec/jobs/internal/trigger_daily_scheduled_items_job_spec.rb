require 'rails_helper'

RSpec.describe Internal::TriggerDailyScheduledItemsJob do
  subject(:perform_job) { described_class.perform_now }

  let(:installation_id) { 'test-installation-id' }
  let(:designated_minute) { Digest::MD5.hexdigest(installation_id).hex % 1440 }
  let(:scheduled_time) { Time.current.utc.beginning_of_day + designated_minute.minutes }
  let(:configured_job) { instance_double(ActiveJob::ConfiguredJob, perform_later: true) }

  before do
    allow(ChatwootHub).to receive(:installation_identifier).and_return(installation_id)
    allow(Internal::CheckNewVersionsJob).to receive(:set).and_return(configured_job)
  end

  it 'enqueues the job' do
    expect { described_class.perform_later }.to have_enqueued_job(described_class)
      .on_queue('scheduled_jobs')
  end

  it 'schedules the version check at a stable minute in production' do
    allow(Rails.env).to receive(:production?).and_return(true)

    travel_to Time.zone.parse('2026-03-17 08:00:00 UTC') do
      perform_job

      expect(Internal::CheckNewVersionsJob).to have_received(:set).with(wait_until: scheduled_time)
      expect(configured_job).to have_received(:perform_later)
    end
  end

  it 'does not schedule the version check outside production' do
    allow(Rails.env).to receive(:production?).and_return(false)

    perform_job

    expect(Internal::CheckNewVersionsJob).not_to have_received(:set)
  end
end
