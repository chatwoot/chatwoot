# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UniformNotifier::Slack do
  context 'not enabled' do
    it 'should not notify slack' do
      expect_any_instance_of(Slack::Notifier).to_not receive(:ping)
      expect(UniformNotifier::Slack.out_of_channel_notify(title: 'notify slack')).to be_nil
    end
  end

  context 'configuration' do
    context 'no webhook_url is given' do
      it 'should raise an error' do
        expect { UniformNotifier.slack = {} }
          .to raise_error(UniformNotifier::NotificationError)
      end

      it 'should not notify slack' do
        begin
          UniformNotifier.slack = {}
        rescue UniformNotifier::NotificationError
        ensure
          expect_any_instance_of(Slack::Notifier).to_not receive(:ping)
          expect(UniformNotifier::Slack.out_of_channel_notify(title: 'notify slack')).to be_nil
        end
      end
    end

    it 'should remove invalid options' do
      expect(Slack::Notifier).to receive(:new).with('http://some.slack.url', {}).and_return(true)
      UniformNotifier.slack = { webhook_url: 'http://some.slack.url', pizza: 'pepperoni' }
      expect(UniformNotifier::Slack.active?).to eq true
    end

    it 'should allow username and channel config options' do
      expect(Slack::Notifier).to receive(:new)
        .with('http://some.slack.url', { username: 'The Dude', channel: '#carpets' })
        .and_return(true)
      UniformNotifier.slack = { webhook_url: 'http://some.slack.url', username: 'The Dude', channel: '#carpets' }
      expect(UniformNotifier::Slack.active?).to eq true
    end
  end

  context 'properly configured' do
    before(:example) do
      @message = 'notify slack'
      allow_any_instance_of(Slack::Notifier).to receive(:ping).and_return(@message)
    end

    it 'should notify slack' do
      UniformNotifier.slack = { webhook_url: 'http://some.slack.url' }
      expect_any_instance_of(Slack::Notifier).to receive(:ping)
      expect(UniformNotifier::Slack.out_of_channel_notify(title: @message)).to eq @message
    end
  end
end
