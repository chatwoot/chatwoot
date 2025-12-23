# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UniformNotifier::TerminalNotifier do
  it 'should not notify terminal-notifier when disabled' do
    expect(UniformNotifier::TerminalNotifier.out_of_channel_notify(title: 'notify terminal')).to be_nil
  end

  it "should raise an exception when terminal-notifier gem isn't available" do
    UniformNotifier.terminal_notifier = true
    expect {
      UniformNotifier::TerminalNotifier.out_of_channel_notify(body: 'body', title: 'notify terminal')
    }.to raise_error(UniformNotifier::NotificationError, /terminal-notifier gem/)
  end

  it 'should notify terminal-notifier when enabled' do
    module TerminalNotifier
      # mock TerminalNotifier
    end

    expect(TerminalNotifier).to receive(:notify).with('body', title: 'notify terminal')

    UniformNotifier.terminal_notifier = true
    UniformNotifier::TerminalNotifier.out_of_channel_notify(body: 'body', title: 'notify terminal')
  end
end
