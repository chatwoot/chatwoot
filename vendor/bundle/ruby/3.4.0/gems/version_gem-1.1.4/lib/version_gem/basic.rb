# frozen_string_literal: true

require_relative "error"
require_relative "api"

module VersionGem
  # This is a very *basic* version parser. Others could be built based on this pattern!
  module Basic
    class << self
      def extended(base)
        raise Error, "VERSION must be defined before 'extend #{name}'" unless defined?(base::VERSION)

        base.extend(Api)
      end
    end
  end
end
