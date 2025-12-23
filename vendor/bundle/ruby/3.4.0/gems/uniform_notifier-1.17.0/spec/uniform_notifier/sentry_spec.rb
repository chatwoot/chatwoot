# frozen_string_literal: true

require 'spec_helper'

class Sentry
  # mock Sentry
end

RSpec.describe UniformNotifier::SentryNotifier do
  it 'should not notify sentry' do
    expect(UniformNotifier::SentryNotifier.out_of_channel_notify(title: 'notify sentry')).to be_nil
  end

  it 'should notify sentry' do
    expect(Sentry).to receive(:capture_exception).with(UniformNotifier::Exception.new('notify sentry'))

    UniformNotifier.sentry = true
    UniformNotifier::SentryNotifier.out_of_channel_notify(title: 'notify sentry')
  end

  it 'should notify sentry' do
    expect(Sentry).to receive(:capture_exception).with(UniformNotifier::Exception.new('notify sentry'), foo: :bar)

    UniformNotifier.sentry = { foo: :bar }
    UniformNotifier::SentryNotifier.out_of_channel_notify('notify sentry')
  end
end
