module Sentry
  module TestHelper
    DUMMY_DSN = 'http://12345:67890@sentry.localdomain/sentry/42'

    # Alters the existing SDK configuration with test-suitable options. Mainly:
    # - Sets a dummy DSN instead of `nil` or an actual DSN.
    # - Sets the transport to DummyTransport, which allows easy access to the captured events.
    # - Disables background worker.
    # - Makes sure the SDK is enabled under the current environment ("test" in most cases).
    #
    # It should be called **before** every test case.
    #
    # @yieldparam config [Configuration]
    # @return [void]
    def setup_sentry_test(&block)
      raise "please make sure the SDK is initialized for testing" unless Sentry.initialized?
      dummy_config = Sentry.configuration.dup
      # configure dummy DSN, so the events will not be sent to the actual service
      dummy_config.dsn = DUMMY_DSN
      # set transport to DummyTransport, so we can easily intercept the captured events
      dummy_config.transport.transport_class = Sentry::DummyTransport
      # make sure SDK allows sending under the current environment
      dummy_config.enabled_environments += [dummy_config.environment] unless dummy_config.enabled_environments.include?(dummy_config.environment)
      # disble async event sending
      dummy_config.background_worker_threads = 0

      # user can overwrite some of the configs, with a few exceptions like:
      # - include_local_variables
      # - auto_session_tracking
      block&.call(dummy_config)

      # the base layer's client should already use the dummy config so nothing will be sent by accident
      base_client = Sentry::Client.new(dummy_config)
      Sentry.get_current_hub.bind_client(base_client)
      # create a new layer so mutations made to the testing scope or configuration could be simply popped later
      Sentry.get_current_hub.push_scope
      test_client = Sentry::Client.new(dummy_config.dup)
      Sentry.get_current_hub.bind_client(test_client)
    end

    # Clears all stored events and envelopes.
    # It should be called **after** every test case.
    # @return [void]
    def teardown_sentry_test
      return unless Sentry.initialized?

      # pop testing layer created by `setup_sentry_test`
      # but keep the base layer to avoid nil-pointer errors
      # TODO: find a way to notify users if they somehow popped the test layer before calling this method
      if Sentry.get_current_hub.instance_variable_get(:@stack).size > 1
        Sentry.get_current_hub.pop_scope
      end
      Sentry::Scope.global_event_processors.clear
    end

    # @return [Transport]
    def sentry_transport
      Sentry.get_current_client.transport
    end

    # Returns the captured event objects.
    # @return [Array<Event>]
    def sentry_events
      sentry_transport.events
    end

    # Returns the captured envelope objects.
    # @return [Array<Envelope>]
    def sentry_envelopes
      sentry_transport.envelopes
    end

    # Returns the last captured event object.
    # @return [Event, nil]
    def last_sentry_event
      sentry_events.last
    end

    # Extracts SDK's internal exception container (not actual exception objects) from an given event.
    # @return [Array<Sentry::SingleExceptionInterface>]
    def extract_sentry_exceptions(event)
      event&.exception&.values || []
    end
  end
end
