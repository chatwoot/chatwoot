# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks that jobs subclass `ApplicationJob` with Rails 5.0.
      #
      # @safety
      #   This cop's autocorrection is unsafe because it may let the logic from `ApplicationJob`
      #   sneak into a job that is not purposed to inherit logic common among other jobs.
      #
      # @example
      #
      #  # good
      #  class Rails5Job < ApplicationJob
      #    # ...
      #  end
      #
      #  # bad
      #  class Rails4Job < ActiveJob::Base
      #    # ...
      #  end
      class ApplicationJob < Base
        extend AutoCorrector
        extend TargetRailsVersion

        minimum_target_rails_version 5.0

        MSG = 'Jobs should subclass `ApplicationJob`.'
        SUPERCLASS = 'ApplicationJob'
        BASE_PATTERN = '(const (const {nil? cbase} :ActiveJob) :Base)'

        # rubocop:disable Layout/ClassStructure
        include RuboCop::Cop::EnforceSuperclass
        # rubocop:enable Layout/ClassStructure

        def autocorrect(node)
          lambda do |corrector|
            corrector.replace(node, self.class::SUPERCLASS)
          end
        end
      end
    end
  end
end
