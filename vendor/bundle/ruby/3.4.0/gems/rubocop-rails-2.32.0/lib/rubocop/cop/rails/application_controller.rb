# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks that controllers subclass `ApplicationController`.
      #
      # @safety
      #   This cop's autocorrection is unsafe because it may let the logic from `ApplicationController`
      #   sneak into a controller that is not purposed to inherit logic common among other controllers.
      #
      # @example
      #
      #  # good
      #  class MyController < ApplicationController
      #    # ...
      #  end
      #
      #  # bad
      #  class MyController < ActionController::Base
      #    # ...
      #  end
      class ApplicationController < Base
        extend AutoCorrector

        MSG = 'Controllers should subclass `ApplicationController`.'
        SUPERCLASS = 'ApplicationController'
        BASE_PATTERN = '(const (const {nil? cbase} :ActionController) :Base)'

        # rubocop:disable Layout/ClassStructure
        include RuboCop::Cop::EnforceSuperclass
        # rubocop:enable Layout/ClassStructure
      end
    end
  end
end
