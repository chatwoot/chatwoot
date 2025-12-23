module NewrelicSidekiqMetrics
  class Middleware
    def call(*)
      Recorder.new.call
      yield
    end
  end
end
