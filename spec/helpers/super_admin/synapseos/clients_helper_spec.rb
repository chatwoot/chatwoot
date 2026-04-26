require 'rails_helper'

RSpec.describe SuperAdmin::Synapseos::ClientsHelper do
  describe '#synapseos_format_snapshot_ts' do
    it 'formats a UTC timestamp as UTC even when Time.zone is non-UTC' do
      Time.use_zone('America/Sao_Paulo') do
        expect(helper.synapseos_format_snapshot_ts('2026-04-24T12:00:00Z')).to eq('2026-04-24 12:00:00 UTC')
      end
    end
  end
end
