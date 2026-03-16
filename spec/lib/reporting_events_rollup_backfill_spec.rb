require 'rails_helper'
require 'rake'

Rails.application.load_tasks unless Object.const_defined?(:ReportingEventsRollupBackfill)

describe ReportingEventsRollupBackfill do
  let(:service) { described_class.new }
  let(:account) { create(:account, reporting_timezone: 'America/New_York') }
  let(:date) { Date.new(2026, 2, 11) }

  describe '#execute_backfill' do
    before do
      allow(ReportingEvents::BackfillService).to receive(:backfill_date)
      allow($stdout).to receive(:flush)
    end

    it 'prompts to enable the read path only after a successful backfill' do
      allow(service).to receive(:print_success)

      expect(service).to receive(:prompt_enable_rollup_read_path).with(account)

      service.send(:execute_backfill, account, date, date, 1)
    end

    it 'does not prompt to enable the read path when backfill fails' do
      allow(ReportingEvents::BackfillService).to receive(:backfill_date).and_raise(StandardError, 'boom')

      expect(service).not_to receive(:prompt_enable_rollup_read_path)

      expect do
        service.send(:execute_backfill, account, date, date, 1)
      end.to raise_error(SystemExit)
    end
  end

  describe '#prompt_enable_rollup_read_path' do
    it 'enables the feature flag when the user confirms' do
      allow($stdin).to receive(:gets).and_return("y\n")

      expect(account).to receive(:enable_features!).with('reporting_events_rollup')

      service.send(:prompt_enable_rollup_read_path, account)
    end

    it 'does not enable the feature flag when the user declines' do
      allow($stdin).to receive(:gets).and_return("n\n")

      expect(account).not_to receive(:enable_features!)

      service.send(:prompt_enable_rollup_read_path, account)
    end
  end
end
