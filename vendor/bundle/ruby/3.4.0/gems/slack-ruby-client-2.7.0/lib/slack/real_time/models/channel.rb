# frozen_string_literal: true

module Slack
  module RealTime
    module Models
      class Channel < Base
        def is_public? # rubocop:disable Naming/PredicateName
          !is_private?
        end
      end
    end
  end
end
