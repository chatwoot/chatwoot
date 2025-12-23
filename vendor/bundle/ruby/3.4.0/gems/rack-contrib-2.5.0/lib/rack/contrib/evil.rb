# frozen_string_literal: true

module Rack
  class Evil
    # Lets you return a response to the client immediately from anywhere ( M V or C ) in the code.
    def initialize(app)
      @app = app
    end

    def call(env)
      catch(:response) { @app.call(env) }
    end
  end
end
