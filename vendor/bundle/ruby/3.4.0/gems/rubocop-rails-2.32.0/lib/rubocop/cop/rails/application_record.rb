# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks that models subclass `ApplicationRecord` with Rails 5.0.
      #
      # It is a common practice to define models inside migrations in order to retain forward
      # compatibility by avoiding loading any application code. And so migration files are excluded
      # by default for this cop.
      #
      # @safety
      #   This cop's autocorrection is unsafe because it may let the logic from `ApplicationRecord`
      #   sneak into an Active Record model that is not purposed to inherit logic common among other
      #   Active Record models.
      #
      # @example
      #
      #  # good
      #  class Rails5Model < ApplicationRecord
      #    # ...
      #  end
      #
      #  # bad
      #  class Rails4Model < ActiveRecord::Base
      #    # ...
      #  end
      class ApplicationRecord < Base
        extend AutoCorrector
        extend TargetRailsVersion

        minimum_target_rails_version 5.0

        MSG = 'Models should subclass `ApplicationRecord`.'
        SUPERCLASS = 'ApplicationRecord'
        BASE_PATTERN = '(const (const {nil? cbase} :ActiveRecord) :Base)'

        # rubocop:disable Layout/ClassStructure
        include RuboCop::Cop::EnforceSuperclass
        # rubocop:enable Layout/ClassStructure
      end
    end
  end
end
