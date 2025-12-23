# frozen_string_literal: true

module WebMock
  module API
    extend self

    def stub_request(method, uri)
      WebMock::StubRegistry.instance.
        register_request_stub(WebMock::RequestStub.new(method, uri))
    end

    alias_method :stub_http_request, :stub_request

    def a_request(method, uri)
      WebMock::RequestPattern.new(method, uri)
    end

    class << self
      alias :request :a_request
    end

    def assert_requested(*args, &block)
      if not args[0].is_a?(WebMock::RequestStub)
        args = convert_uri_method_and_options_to_request_and_options(args[0], args[1], args[2], &block)
      elsif block
        raise ArgumentError, "assert_requested with a stub object, doesn't accept blocks"
      end
      assert_request_requested(*args)
    end

    def assert_not_requested(*args, &block)
      if not args[0].is_a?(WebMock::RequestStub)
        args = convert_uri_method_and_options_to_request_and_options(args[0], args[1], args[2], &block)
      elsif block
        raise ArgumentError, "assert_not_requested with a stub object, doesn't accept blocks"
      end
      assert_request_not_requested(*args)
    end
    alias refute_requested assert_not_requested

    # Similar to RSpec::Mocks::ArgumentMatchers#hash_including()
    #
    # Matches a hash that includes the specified key(s) or key/value pairs.
    # Ignores any additional keys.
    #
    # @example
    #
    #   object.should_receive(:message).with(hash_including(:key => val))
    #   object.should_receive(:message).with(hash_including(:key))
    #   object.should_receive(:message).with(hash_including(:key, :key2 => val2))
    def hash_including(*args)
      if defined?(super)
        super
      else
        WebMock::Matchers::HashIncludingMatcher.new(anythingize_lonely_keys(*args))
      end
    end

    def hash_excluding(*args)
      if defined?(super)
        super
      else
        WebMock::Matchers::HashExcludingMatcher.new(anythingize_lonely_keys(*args))
      end
    end

    def remove_request_stub(stub)
      WebMock::StubRegistry.instance.remove_request_stub(stub)
    end

    def reset_executed_requests!
      WebMock::RequestRegistry.instance.reset!
    end

    private

    def convert_uri_method_and_options_to_request_and_options(method, uri, options, &block)
      options ||= {}
      options_for_pattern = options.dup
      [:times, :at_least_times, :at_most_times].each { |key| options_for_pattern.delete(key) }
      request = WebMock::RequestPattern.new(method, uri, options_for_pattern)
      request = request.with(&block) if block
      [request, options]
    end

    def assert_request_requested(request, options = {})
      times = options.delete(:times)
      at_least_times = options.delete(:at_least_times)
      at_most_times  = options.delete(:at_most_times)
      times = 1 if times.nil? && at_least_times.nil? && at_most_times.nil?
      verifier = WebMock::RequestExecutionVerifier.new(request, times, at_least_times, at_most_times)
      WebMock::AssertionFailure.failure(verifier.failure_message) unless verifier.matches?
    end

    def assert_request_not_requested(request, options = {})
      times = options.delete(:times)
      at_least_times = options.delete(:at_least_times)
      at_most_times  = options.delete(:at_most_times)
      verifier = WebMock::RequestExecutionVerifier.new(request, times, at_least_times, at_most_times)
      WebMock::AssertionFailure.failure(verifier.failure_message_when_negated) unless verifier.does_not_match?
    end

    #this is a based on RSpec::Mocks::ArgumentMatchers#anythingize_lonely_keys
    def anythingize_lonely_keys(*args)
      hash = args.last.class == Hash ? args.delete_at(-1) : {}
      args.each { | arg | hash[arg] =  WebMock::Matchers::AnyArgMatcher.new(nil) }
      hash
    end

  end
end
