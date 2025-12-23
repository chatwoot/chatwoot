# frozen_string_literal: true

require 'spec_helper'

class Rails
  # mock Rails
end

RSpec.describe UniformNotifier::RailsLogger do
  it 'should not notify rails logger' do
    expect(UniformNotifier::RailsLogger.out_of_channel_notify(title: 'notify rails logger')).to be_nil
  end

  it 'should notify rails logger' do
    logger = double('logger')
    expect(Rails).to receive(:logger).and_return(logger)
    expect(logger).to receive(:warn).with('notify rails logger')

    UniformNotifier.rails_logger = true
    UniformNotifier::RailsLogger.out_of_channel_notify(title: 'notify rails logger')
  end
end
