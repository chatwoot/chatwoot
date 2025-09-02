module Weave
  module Core
    class PingController < ApplicationController
      def index
        render json: { ok: true }
      end
    end
  end
end

