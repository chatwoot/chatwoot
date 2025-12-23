# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UniformNotifier::Raise do
  it 'should not notify message' do
    expect(UniformNotifier::Raise.out_of_channel_notify(title: 'notification')).to be_nil
  end

  it 'should raise error of the default class' do
    UniformNotifier.raise = true
    expect { UniformNotifier::Raise.out_of_channel_notify(title: 'notification') }
      .to raise_error(
        UniformNotifier::Exception,
        'notification'
      )
  end

  it 'allows the user to override the default exception class' do
    klass = Class.new(RuntimeError)
    UniformNotifier.raise = klass
    expect { UniformNotifier::Raise.out_of_channel_notify(title: 'notification') }
      .to raise_error(klass, 'notification')
  end

  it 'can be turned from on to off again' do
    UniformNotifier.raise = true
    UniformNotifier.raise = false

    expect { UniformNotifier::Raise.out_of_channel_notify(title: 'notification') }
      .not_to raise_error
  end
end
