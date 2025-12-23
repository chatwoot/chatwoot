# frozen_string_literal: true

module Sentry
  class DummyTransport < Transport
    attr_accessor :events, :envelopes

    def initialize(*)
      super
      @events = []
      @envelopes = []
    end

    def send_event(event)
      @events << event
    end

    def send_envelope(envelope)
      @envelopes << envelope
    end
  end
end
