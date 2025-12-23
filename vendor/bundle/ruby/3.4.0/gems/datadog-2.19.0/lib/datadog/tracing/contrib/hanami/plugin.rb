# frozen_string_literal: true

::Hanami.plugin do
  Datadog.configure do |c|
    c.tracing.instrument :rack
  end

  middleware.use Datadog::Tracing::Contrib::Rack::TraceMiddleware
end

::Hanami::Application.singleton_class.prepend(
  Module.new do
    def inherited(base)
      super

      base.configure do
        controller.prepare do
          use Datadog::Tracing::Contrib::Hanami::ActionTracer, self
        end
      end
    end
  end
)
