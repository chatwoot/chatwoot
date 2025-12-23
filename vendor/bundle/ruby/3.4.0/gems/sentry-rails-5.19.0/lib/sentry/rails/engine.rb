module Sentry
  class Engine < ::Rails::Engine
    isolate_namespace Sentry
  end
end
