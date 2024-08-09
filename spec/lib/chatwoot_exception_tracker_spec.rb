require 'rails_helper'
# explicitly requiring since we are loading apms conditionally in application.rb
require 'sentry-ruby'

describe ChatwootExceptionTracker do
  it 'use rails logger if no tracker is configured' do
    expect(Rails.logger).to receive(:error).with('random')
    described_class.new('random').capture_exception
  end

  context 'with sentry DSN' do
    before do
      # since sentry is not initated in test, we need to do it manually
      Sentry.init do |config|
        config.dsn = 'test'
      end
    end

    it 'will call sentry capture exception' do
      with_modified_env SENTRY_DSN: 'random dsn' do
        expect(Sentry).to receive(:capture_exception).with('random')
        described_class.new('random').capture_exception
      end
    end

    it 'sets additional context when provided' do
      additional_context = { key1: 'value1', key2: 'value2' }

      with_modified_env SENTRY_DSN: 'random dsn' do
        scope = instance_double(Sentry::Scope)
        allow(Sentry).to receive(:with_scope).and_yield(scope)

        expect(scope).to receive(:set_context).with('key1', 'value1')
        expect(scope).to receive(:set_context).with('key2', 'value2')
        expect(Sentry).to receive(:capture_exception).with('random')

        described_class.new('random', additional_context: additional_context).capture_exception
      end
    end
  end
end
