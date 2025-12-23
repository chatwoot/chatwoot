# frozen_string_literal: true

require 'spec_helper'

class OpenTelemetry
  class Trace
    # mock OpenTelemetry
  end
end

RSpec.describe UniformNotifier::OpenTelemetryNotifier do
  it 'should not notify OpenTelemetry' do
    expect(UniformNotifier::OpenTelemetryNotifier.out_of_channel_notify(title: 'notify otel')).to be_nil
  end

  it 'should notify OpenTelemetry' do
    span = double('span')
    expect(span).to receive(:record_exception).with(UniformNotifier::Exception.new('notify otel'))
    expect(OpenTelemetry::Trace).to receive(:current_span).and_return(span)

    UniformNotifier.opentelemetry = true
    UniformNotifier::OpenTelemetryNotifier.out_of_channel_notify(title: 'notify otel')
  end

  it 'should notify OpenTelemetry' do
    span = double('span')
    expect(span).to receive(:record_exception).with(UniformNotifier::Exception.new('notify otel'))
    expect(OpenTelemetry::Trace).to receive(:current_span).and_return(span)

    UniformNotifier.opentelemetry = { foo: :bar }
    UniformNotifier::OpenTelemetryNotifier.out_of_channel_notify('notify otel')
  end
end
