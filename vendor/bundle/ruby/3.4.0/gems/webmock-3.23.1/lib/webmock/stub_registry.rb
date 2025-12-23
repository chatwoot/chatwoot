# frozen_string_literal: true

module WebMock

  class StubRegistry
    include Singleton

    attr_accessor :request_stubs

    def initialize
      reset!
    end

    def global_stubs
      @global_stubs ||= Hash.new { |h, k| h[k] = [] }
    end

    def reset!
      self.request_stubs = []
    end

    def register_global_stub(order = :before_local_stubs, &block)
      unless %i[before_local_stubs after_local_stubs].include?(order)
        raise ArgumentError.new("Wrong order. Use :before_local_stubs or :after_local_stubs")
      end

      # This hash contains the responses returned by the block,
      # keyed by the exact request (using the object_id).
      # That way, there's no race condition in case #to_return
      # doesn't run immediately after stub.with.
      responses = {}
      response_lock = Mutex.new

      stub = ::WebMock::RequestStub.new(:any, ->(uri) { true }).with { |request|
        update_response = -> { responses[request.object_id] = yield(request) }

        # The block can recurse, so only lock if we don't already own it
        if response_lock.owned?
          update_response.call
        else
          response_lock.synchronize(&update_response)
        end
      }.to_return(lambda { |request|
        response_lock.synchronize { responses.delete(request.object_id) }
      })

      global_stubs[order].push stub
    end

    def register_request_stub(stub)
      request_stubs.insert(0, stub)
      stub
    end

    def remove_request_stub(stub)
      if not request_stubs.delete(stub)
        raise "Request stub \n\n #{stub.to_s} \n\n is not registered."
      end
    end

    def registered_request?(request_signature)
      request_stub_for(request_signature)
    end

    def response_for_request(request_signature)
      stub = request_stub_for(request_signature)
      stub ? evaluate_response_for_request(stub.response, request_signature) : nil
    end

    private

    def request_stub_for(request_signature)
      (global_stubs[:before_local_stubs] + request_stubs + global_stubs[:after_local_stubs])
        .detect { |registered_request_stub|
          registered_request_stub.request_pattern.matches?(request_signature)
        }
    end

    def evaluate_response_for_request(response, request_signature)
      response.dup.evaluate(request_signature)
    end

  end
end
