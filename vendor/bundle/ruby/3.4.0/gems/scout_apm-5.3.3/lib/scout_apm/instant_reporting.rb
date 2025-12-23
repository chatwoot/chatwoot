# InstantReporting is used when a specially flagged request hits the application.
# The agent traces the request regardless of its performance characteristics, and reports it immediately to our servers, for instant feedback.
# The request is detected in the ActionController instrumentation, and flagged in TrackedRequest. The trace is prepped here, and handed off to a Reporter for the actual POST.
module ScoutApm
  class InstantReporting
    # trace is an instance of SlowTransaction
    # instant_key is what was passed in from the browser to trigger the instant trace
    def initialize(trace, instant_key)
      @trace = trace
      @instant_key = instant_key
    end

    def call
      Thread.new do
        # Serialize that trace. We reuse the PayloadSerializer, but only provide the metadata and traces.
        # In this case, the traces array will always have just one element.
        metadata = {
          :app_root      => ScoutApm::Agent.instance.context.environment.root.to_s,
          :unique_id     => ScoutApm::Utils::UniqueId.simple,
          :agent_version => ScoutApm::VERSION,
          :agent_time    => Time.now.iso8601,
          :agent_pid     => Process.pid,
          :platform      => "ruby",
        }

        metrics = []
        traces = [@trace]
        jobs = []
        slow_jobs = []

        payload = ScoutApm::Serializers::PayloadSerializer.serialize(metadata, metrics, traces, jobs, slow_jobs)

        # Hand it off to the reporter for POST to our servers
        reporter = Reporter.new(context, :instant_trace, @instant_key)
        reporter.report(payload, {'Content-Type' => 'application/json'} )
      end
    end

  end
end
