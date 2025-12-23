# frozen_string_literal: true

require 'spec_helper'

class Bugsnag
  # mock Bugsnag
end

RSpec.describe UniformNotifier::BugsnagNotifier do
  let(:notification_data) { {} }
  let(:report) { double('Bugsnag::Report') }
  before do
    allow(report).to receive(:severity=)
    allow(report).to receive(:add_tab)
    allow(report).to receive(:grouping_hash=)
  end
  it 'should not notify bugsnag' do
    expect(Bugsnag).not_to receive(:notify)
    UniformNotifier::BugsnagNotifier.out_of_channel_notify(notification_data)
  end
  context 'with string notification' do
    let(:notification_data) { 'notify bugsnag' }

    it 'should notify bugsnag' do
      expect(Bugsnag).to receive(:notify).with(UniformNotifier::Exception.new(notification_data)).and_yield(report)
      expect(report).to receive(:severity=).with('warning')
      expect(report).to receive(:add_tab).with(:bullet, { title: notification_data })
      expect(report).to receive(:grouping_hash=).with(notification_data)

      UniformNotifier.bugsnag = true
      UniformNotifier::BugsnagNotifier.out_of_channel_notify(notification_data)
    end

    it 'should notify bugsnag with additional report configuration' do
      expect(Bugsnag).to receive(:notify).with(UniformNotifier::Exception.new(notification_data)).and_yield(report)
      expect(report).to receive(:meta_data=).with({ foo: :bar })

      UniformNotifier.bugsnag = ->(report) { report.meta_data = { foo: :bar } }
      UniformNotifier::BugsnagNotifier.out_of_channel_notify(notification_data)
    end
  end
  context 'with hash notification' do
    let(:notification_data) { { user: 'user', title: 'notify bugsnag', url: 'URL', body: 'something' } }

    it 'should notify bugsnag' do
      expect(Bugsnag).to receive(:notify).with(
        UniformNotifier::Exception.new(notification_data[:title])
      ).and_yield(report)
      expect(report).to receive(:severity=).with('warning')
      expect(report).to receive(:add_tab).with(:bullet, notification_data)
      expect(report).to receive(:grouping_hash=).with(notification_data[:body])

      UniformNotifier.bugsnag = true
      UniformNotifier::BugsnagNotifier.out_of_channel_notify(notification_data)
    end

    it 'should notify bugsnag with option' do
      expect(Bugsnag).to receive(:notify).with(
        UniformNotifier::Exception.new(notification_data[:title])
      ).and_yield(report)
      expect(report).to receive(:meta_data=).with({ foo: :bar })

      UniformNotifier.bugsnag = ->(report) { report.meta_data = { foo: :bar } }
      UniformNotifier::BugsnagNotifier.out_of_channel_notify(notification_data)
    end
  end

  it 'should notify bugsnag with correct backtrace' do
    expect(Bugsnag).to receive(:notify) do |error|
      expect(error).to be_a UniformNotifier::Exception
      expect(error.backtrace).to eq ['bugsnag spec test']
    end
    UniformNotifier.bugsnag = true
    UniformNotifier::BugsnagNotifier.out_of_channel_notify(backtrace: ['bugsnag spec test'])
  end
end
