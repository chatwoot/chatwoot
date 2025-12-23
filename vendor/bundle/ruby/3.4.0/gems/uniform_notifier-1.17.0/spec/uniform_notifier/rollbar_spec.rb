# frozen_string_literal: true

require 'spec_helper'

class Rollbar
  # mock Rollbar
end

RSpec.describe UniformNotifier::RollbarNotifier do
  it 'should not notify rollbar' do
    expect(UniformNotifier::RollbarNotifier.out_of_channel_notify(title: 'notify rollbar')).to be_nil
  end

  it 'should notify rollbar' do
    expect(Rollbar).to receive(:log).with('info', UniformNotifier::Exception.new('notify rollbar'))

    UniformNotifier.rollbar = true
    UniformNotifier::RollbarNotifier.out_of_channel_notify(title: 'notify rollbar')
  end

  it 'should notify rollbar' do
    expect(Rollbar).to receive(:log).with('warning', UniformNotifier::Exception.new('notify rollbar'))

    UniformNotifier.rollbar = { level: 'warning' }
    UniformNotifier::RollbarNotifier.out_of_channel_notify(title: 'notify rollbar')
  end
end
