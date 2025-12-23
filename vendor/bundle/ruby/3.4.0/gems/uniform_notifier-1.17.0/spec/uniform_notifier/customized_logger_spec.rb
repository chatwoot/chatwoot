# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UniformNotifier::CustomizedLogger do
  it 'should not notify to customized logger' do
    expect(UniformNotifier::CustomizedLogger.out_of_channel_notify(title: 'notify rails logger')).to be_nil
  end

  it 'should notify to customized logger' do
    logger = File.open('test.log', 'a+')
    logger.sync = true

    now = Time.now
    allow(Time).to receive(:now).and_return(now)
    UniformNotifier.customized_logger = logger
    UniformNotifier::CustomizedLogger.out_of_channel_notify(title: 'notify rails logger')

    logger.seek(0)
    expect(logger.read).to eq "#{now.strftime('%Y-%m-%d %H:%M:%S')}[WARN] notify rails logger"

    File.delete('test.log')
  end
end
