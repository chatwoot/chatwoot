# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    # This class is used for instrumentations that have exceptions or error classes
    # not derived from Ruby's usual Exception or StandardError or in situations
    # where we do not have such Exception object to work with.
    class NoticeableError
      attr_reader :class_name, :message

      def initialize(class_name, message)
        @class_name = class_name
        @message = message
      end
    end
  end
end
