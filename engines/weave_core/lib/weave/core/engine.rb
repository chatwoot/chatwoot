require "rails/engine"

module Weave
  module Core
    class Engine < ::Rails::Engine
      isolate_namespace Weave::Core

      initializer "weave.core.append_migrations" do |app|
        unless app.root.to_s.start_with?(root.to_s)
          app.config.paths["db/migrate"].concat(config.paths["db/migrate"].expanded)
        end
      end
    end
  end
end
