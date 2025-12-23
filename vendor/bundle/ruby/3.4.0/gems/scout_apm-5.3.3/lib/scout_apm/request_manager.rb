# Request manager handles the threadlocal variable that holds the current
# request. If there isn't one, then create one

module ScoutApm
  class RequestManager
    def self.lookup
      find || create
    end

    # Get the current Thread local, and detecting, and not returning a stale request
    def self.find
      req = Thread.current[:scout_request]

      if req && (req.stopping? || req.recorded?)
        nil
      else
        req
      end
    end

    # Create a new TrackedRequest object for this thread
    # XXX: Figure out who is in charge of creating a `FakeStore` - previously was here
    def self.create
      agent_context = ScoutApm::Agent.instance.context
      store = agent_context.store
      Thread.current[:scout_request] = TrackedRequest.new(agent_context, store)
    end
  end
end
