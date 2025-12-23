# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UniformNotifier::Xmpp do
  it 'should not notify xmpp' do
    expect(UniformNotifier::Xmpp.out_of_channel_notify(title: 'notify xmpp')).to be_nil
  end

  it 'should notify xmpp without online status' do
    jid = double('jid')
    xmpp = double('xmpp')
    expect(Jabber::JID).to receive(:new).with('from@gmail.com').and_return(jid)
    expect(Jabber::Client).to receive(:new).with(jid).and_return(xmpp)
    expect(xmpp).to receive(:connect)
    expect(xmpp).to receive(:auth).with('123456')

    message = double('message')
    expect(Jabber::Message).to receive(:new).with('to@gmail.com', 'notify xmpp').and_return(message)
    expect(message).to receive(:set_type).with(:normal).and_return(message)
    expect(message).to receive(:set_subject).with('Uniform Notifier').and_return(message)
    expect(xmpp).to receive(:send).with(message)

    UniformNotifier.xmpp = {
      account: 'from@gmail.com',
      password: '123456',
      receiver: 'to@gmail.com',
      show_online_status: false
    }
    UniformNotifier::Xmpp.out_of_channel_notify(title: 'notify xmpp')
  end

  it 'should notify xmpp with online status' do
    jid = double('jid')
    xmpp = double('xmpp')
    expect(Jabber::JID).to receive(:new).with('from@gmail.com').and_return(jid)
    expect(Jabber::Client).to receive(:new).with(jid).and_return(xmpp)
    expect(xmpp).to receive(:connect)
    expect(xmpp).to receive(:auth).with('123456')

    presence = double('presence')
    now = Time.now
    allow(Time).to receive(:now).and_return(now)
    expect(Jabber::Presence).to receive(:new).and_return(presence)
    expect(presence).to receive(:set_status).with("Uniform Notifier started on #{now}").and_return(presence)
    expect(xmpp).to receive(:send).with(presence)

    message = double('message')
    expect(Jabber::Message).to receive(:new).with('to@gmail.com', 'notify xmpp').and_return(message)
    expect(message).to receive(:set_type).with(:normal).and_return(message)
    expect(message).to receive(:set_subject).with('Uniform Notifier').and_return(message)
    expect(xmpp).to receive(:send).with(message)

    UniformNotifier.xmpp = {
      account: 'from@gmail.com',
      password: '123456',
      receiver: 'to@gmail.com',
      show_online_status: true
    }
    UniformNotifier::Xmpp.out_of_channel_notify(title: 'notify xmpp')
  end
end
