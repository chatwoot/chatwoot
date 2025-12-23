# frozen_string_literal: true

module WebMock
  class RequestStub

    attr_accessor :request_pattern

    def initialize(method, uri)
      @request_pattern = RequestPattern.new(method, uri)
      @responses_sequences = []
      self
    end

    def with(params = {}, &block)
      @request_pattern.with(params, &block)
      self
    end

    def to_return(*response_hashes, &block)
      if block
        @responses_sequences << ResponsesSequence.new([ResponseFactory.response_for(block)])
      else
        @responses_sequences << ResponsesSequence.new([*response_hashes].flatten.map {|r| ResponseFactory.response_for(r)})
      end
      self
    end
    alias_method :and_return, :to_return

    def to_return_json(*response_hashes)
      raise ArgumentError, '#to_return_json does not support passing a block' if block_given?

      json_response_hashes = [*response_hashes].flatten.map do |resp_h|
        headers, body = resp_h.values_at(:headers, :body)

        json_body = if body.respond_to?(:call)
          ->(request_signature) {
            b = if body.respond_to?(:arity) && body.arity == 1
              body.call(request_signature)
            else
              body.call
            end
            b = b.to_json unless b.is_a?(String)
            b
          }
        elsif !body.is_a?(String)
          body.to_json
        else
          body
        end

        resp_h.merge(
          headers: {content_type: 'application/json'}.merge(headers.to_h),
          body: json_body
        )
      end

      to_return(json_response_hashes)
    end
    alias_method :and_return_json, :to_return_json

    def to_rack(app, options={})
      @responses_sequences << ResponsesSequence.new([RackResponse.new(app)])
    end

    def to_raise(*exceptions)
      @responses_sequences << ResponsesSequence.new([*exceptions].flatten.map {|e|
        ResponseFactory.response_for(exception: e)
      })
      self
    end
    alias_method :and_raise, :to_raise

    def to_timeout
      @responses_sequences << ResponsesSequence.new([ResponseFactory.response_for(should_timeout: true)])
      self
    end
    alias_method :and_timeout, :to_timeout

    def response
      if @responses_sequences.empty?
        WebMock::Response.new
      elsif @responses_sequences.length > 1
        @responses_sequences.shift if @responses_sequences.first.end?
        @responses_sequences.first.next_response
      else
        @responses_sequences[0].next_response
      end
    end

    def has_responses?
      !@responses_sequences.empty?
    end

    def then
      self
    end

    def times(number)
      raise "times(N) accepts integers >= 1 only" if !number.is_a?(Integer) || number < 1
      if @responses_sequences.empty?
        raise "Invalid WebMock stub declaration." +
          " times(N) can be declared only after response declaration."
      end
      @responses_sequences.last.times_to_repeat += number-1
      self
    end

    def matches?(request_signature)
      self.request_pattern.matches?(request_signature)
    end

    def to_s
      self.request_pattern.to_s
    end

    def self.from_request_signature(signature)
      stub = self.new(signature.method.to_sym, signature.uri.to_s)

      if signature.body.to_s != ''
        body = if signature.url_encoded?
          WebMock::Util::QueryMapper.query_to_values(signature.body, notation: Config.instance.query_values_notation)
        else
          signature.body
        end
        stub.with(body: body)
      end

      if (signature.headers && !signature.headers.empty?)
        stub.with(headers: signature.headers)
      end
      stub
    end
  end
end
