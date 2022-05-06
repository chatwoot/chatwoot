require 'rails_helper'

describe ChatwootExceptionTracker do
  it 'returns nil if no tracker is configured' do
    expect(described_class.new('random').capture_exception).to eq(nil)
  end

  context 'with sentry DSN' do
    it 'will call sentry capture exception' do
      with_modified_env SENTRY_DSN: 'random dsn' do
        expect(Sentry).to receive(:capture_exception).with('random')
        described_class.new('random').capture_exception
      end
    end
  end
end
