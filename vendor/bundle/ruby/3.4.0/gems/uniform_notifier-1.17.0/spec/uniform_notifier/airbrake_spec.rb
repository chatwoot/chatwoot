# frozen_string_literal: true

require 'spec_helper'

class Airbrake
  # mock Airbrake
end

RSpec.describe UniformNotifier::AirbrakeNotifier do
  it 'should not notify airbrake' do
    expect(UniformNotifier::AirbrakeNotifier.out_of_channel_notify(title: 'notify airbrake')).to be_nil
  end

  it 'should notify airbrake' do
    expect(Airbrake).to receive(:notify).with(UniformNotifier::Exception.new('notify airbrake'), {})

    UniformNotifier.airbrake = true
    UniformNotifier::AirbrakeNotifier.out_of_channel_notify(title: 'notify airbrake')
  end

  it 'should notify airbrake' do
    expect(Airbrake).to receive(:notify).with(UniformNotifier::Exception.new('notify airbrake'), { foo: :bar })

    UniformNotifier.airbrake = { foo: :bar }
    UniformNotifier::AirbrakeNotifier.out_of_channel_notify('notify airbrake')
  end
end
