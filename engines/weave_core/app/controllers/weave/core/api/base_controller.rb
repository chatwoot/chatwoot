module Weave
  module Core
    module Api
      class BaseController < ::Api::BaseController
        include ::EnsureCurrentAccountHelper
      end
    end
  end
end

