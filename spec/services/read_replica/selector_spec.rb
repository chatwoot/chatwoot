require 'rails_helper'

RSpec.describe ReadReplica::Selector do
  subject(:selection) { described_class.new(actor_key: actor_key, max_lag: max_lag).select }

  let(:actor_key) { 'account:1:user:2' }
  let(:max_lag) { 2 }
  let(:replica_enabled) { 'true' }

  around do |example|
    with_modified_env POSTGRES_REPLICA_ENABLED: replica_enabled do
      example.run
    end
  end

  before do
    allow(ReadReplica::WriterStickiness).to receive(:sticky?).with(actor_key).and_return(false)
    allow(ReadReplica::Health).to receive(:status).and_return(
      ReadReplica::Health::Status.new(healthy: true, lag_seconds: 1.5, checked_at: 0)
    )
  end

  context 'when replica routing is disabled' do
    let(:replica_enabled) { 'false' }

    it 'uses the writer without checking replica state' do
      expect(ReadReplica::WriterStickiness).not_to receive(:sticky?)
      expect(ReadReplica::Health).not_to receive(:status)

      expect(selection.to_h).to eq(role: :writing, reason: :disabled, lag_seconds: nil)
    end
  end

  context 'when the actor is writer-sticky' do
    before { allow(ReadReplica::WriterStickiness).to receive(:sticky?).with(actor_key).and_return(true) }

    it 'uses the writer without checking replica health' do
      expect(ReadReplica::Health).not_to receive(:status)

      expect(selection.to_h).to eq(role: :writing, reason: :writer_sticky, lag_seconds: nil)
    end
  end

  context 'when the replica is unhealthy' do
    before do
      allow(ReadReplica::Health).to receive(:status).and_return(
        ReadReplica::Health::Status.new(healthy: false, lag_seconds: nil, checked_at: 0)
      )
    end

    it 'uses the writer' do
      expect(selection.to_h).to eq(role: :writing, reason: :unhealthy, lag_seconds: nil)
    end
  end

  context 'when replica lag exceeds the action threshold' do
    before do
      allow(ReadReplica::Health).to receive(:status).and_return(
        ReadReplica::Health::Status.new(healthy: true, lag_seconds: 2.1, checked_at: 0)
      )
    end

    it 'uses the writer and reports the observed lag' do
      expect(selection.to_h).to eq(role: :writing, reason: :lag_exceeded, lag_seconds: 2.1)
    end
  end

  context 'when the replica is healthy and within the action threshold' do
    it 'uses the reader' do
      expect(selection).to be_reader
      expect(selection.to_h).to eq(role: :reading, reason: :eligible, lag_seconds: 1.5)
    end
  end
end
