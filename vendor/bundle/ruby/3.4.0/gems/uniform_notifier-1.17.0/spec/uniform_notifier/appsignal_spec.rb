# frozen_string_literal: true

require 'spec_helper'

class Appsignal
  # mock AppSignal
end

RSpec.describe UniformNotifier::AppsignalNotifier do
  it 'should not notify appsignal' do
    expect(UniformNotifier::AppsignalNotifier.out_of_channel_notify(title: 'notify appsignal')).to be_nil
  end

  it 'should notify appsignal with keyword title' do
    expect(Appsignal).to receive(:send_error).with(UniformNotifier::Exception.new("notify appsignal\n"))

    UniformNotifier.appsignal = true
    expect(UniformNotifier::AppsignalNotifier.out_of_channel_notify(title: 'notify appsignal'))
  end

  it 'should notify appsignal with first argument title' do
    expect(Appsignal).to receive(:send_error).with(
      UniformNotifier::Exception.new("notify appsignal\n")
    )

    UniformNotifier.appsignal = true
    UniformNotifier::AppsignalNotifier.out_of_channel_notify('notify appsignal')
  end

  it 'should notify appsignal with tags' do
    transaction = double('Appsignal::Transaction', set_namespace: nil)
    expect(transaction).to receive(:set_tags).with({ foo: :bar })
    expect(Appsignal).to receive(:send_error).with(
      UniformNotifier::Exception.new("notify appsignal\n")
    ).and_yield(transaction)

    UniformNotifier.appsignal = true
    UniformNotifier::AppsignalNotifier.out_of_channel_notify(title: 'notify appsignal', tags: { foo: :bar })
  end

  it 'should notify appsignal with default namespace' do
    transaction = double('Appsignal::Transaction', set_tags: nil)
    expect(transaction).to receive(:set_namespace).with('web')
    expect(Appsignal).to receive(:send_error).with(
      UniformNotifier::Exception.new("notify appsignal\n")
    ).and_yield(transaction)

    UniformNotifier.appsignal = { namespace: 'web' }
    UniformNotifier::AppsignalNotifier.out_of_channel_notify('notify appsignal')
  end

  it 'should notify appsignal with overridden namespace' do
    transaction = double('Appsignal::Transaction')
    expect(transaction).to receive(:set_tags).with({ foo: :bar })
    expect(transaction).to receive(:set_namespace).with('background')
    expect(Appsignal).to receive(:send_error).with(
      UniformNotifier::Exception.new("notify appsignal\nbody")
    ).and_yield(transaction)

    UniformNotifier.appsignal = { namespace: 'web' }
    UniformNotifier::AppsignalNotifier.out_of_channel_notify(
      title: 'notify appsignal',
      tags: {
        foo: :bar
      },
      namespace: 'background',
      body: 'body',
    )
  end

  it 'should notify appsignal with merged tags' do
    transaction = double('Appsignal::Transaction')
    expect(transaction).to receive(:set_tags).with({ user: 'Bob', hostname: 'frontend2', site: 'first' })
    expect(transaction).to receive(:set_namespace).with('background')
    expect(Appsignal).to receive(:send_error).with(
      UniformNotifier::Exception.new("notify appsignal\nbody")
    ).and_yield(transaction)

    UniformNotifier.appsignal = { namespace: 'web', tags: { hostname: 'frontend1', user: 'Bob' } }
    UniformNotifier::AppsignalNotifier.out_of_channel_notify(
      title: 'notify appsignal',
      tags: {
        hostname: 'frontend2',
        site: 'first'
      },
      body: 'body',
      namespace: 'background'
    )
  end
end
