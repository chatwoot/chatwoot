require "rails/engine"

module Weave
  module Core
    class Engine < ::Rails::Engine
      isolate_namespace Weave::Core
    end
  end
end

