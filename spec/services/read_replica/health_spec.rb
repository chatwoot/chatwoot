require 'rails_helper'

RSpec.describe ReadReplica::Health do
  let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }
  let(:roles) { [] }

  before do
    described_class.reset!
    allow(ApplicationRecord).to receive(:connection).and_return(connection)
    allow(ApplicationRecord).to receive(:connected_to) do |**options, &block|
      roles << options
      block.call
    end
  end

  after { described_class.reset! }

  describe '.status' do
    before do
      allow(connection).to receive(:select_value).with(described_class::PRIMARY_LSN_QUERY).and_return('0/16B6A50')
      allow(connection).to receive(:select_one).and_return('in_recovery' => true, 'lag_seconds' => '0.75')
    end

    it 'compares the writer WAL position on the replica and reports health' do
      status = described_class.status

      expect(status).to have_attributes(healthy: true, lag_seconds: 0.75)
      expect(roles).to eq([{ role: :writing }, { role: :reading, prevent_writes: true }])
      expect(connection).to have_received(:select_one).with(include("'0/16B6A50'::pg_lsn"))
    end

    it 'caches the result for the configured interval' do
      2.times { described_class.status }

      expect(connection).to have_received(:select_value).once
      expect(connection).to have_received(:select_one).once
    end

    it 'reports an unhealthy replica when it is not in recovery' do
      allow(connection).to receive(:select_one).and_return('in_recovery' => false, 'lag_seconds' => '0')

      expect(described_class.status).to have_attributes(healthy: false, lag_seconds: 0.0)
    end

    it 'fails closed when the health query raises' do
      allow(connection).to receive(:select_value).and_raise(ActiveRecord::ConnectionNotEstablished, 'unavailable')

      expect(described_class.status).to have_attributes(healthy: false, lag_seconds: nil)
    end
  end
end
