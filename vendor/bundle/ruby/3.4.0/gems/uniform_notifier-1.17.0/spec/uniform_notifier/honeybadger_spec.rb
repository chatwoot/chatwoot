# frozen_string_literal: true

require 'spec_helper'

class Honeybadger
  # mock Honeybadger
end

RSpec.describe UniformNotifier::HoneybadgerNotifier do
  it 'should not notify honeybadger' do
    expect(UniformNotifier::HoneybadgerNotifier.out_of_channel_notify(title: 'notify honeybadger')).to be_nil
  end

  it 'should notify honeybadger' do
    expect(Honeybadger).to receive(:notify).with(UniformNotifier::Exception.new('notify honeybadger'), {})

    UniformNotifier.honeybadger = true
    UniformNotifier::HoneybadgerNotifier.out_of_channel_notify(title: 'notify honeybadger')
  end

  it 'should notify honeybadger' do
    expect(Honeybadger).to receive(:notify).with(UniformNotifier::Exception.new('notify honeybadger'), { foo: :bar })

    UniformNotifier.honeybadger = { foo: :bar }
    UniformNotifier::HoneybadgerNotifier.out_of_channel_notify('notify honeybadger')
  end
end
