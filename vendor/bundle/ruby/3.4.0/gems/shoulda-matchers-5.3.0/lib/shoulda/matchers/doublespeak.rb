require 'forwardable'
require 'logger'

module Shoulda
  module Matchers
    # @private
    module Doublespeak
      class << self
        extend Forwardable

        def_delegators :world, :double_collection_for,
          :with_doubles_activated

        def world
          @_world ||= World.new
        end

        def debugging_enabled?
          ENV['DEBUG_DOUBLESPEAK'] == '1'
        end

        def debug(&block)
          if debugging_enabled?
            puts block.call # rubocop:disable Rails/Output
          end
        end
      end
    end
  end
end

require 'shoulda/matchers/doublespeak/double'
require 'shoulda/matchers/doublespeak/double_collection'
require 'shoulda/matchers/doublespeak/double_implementation_registry'
require 'shoulda/matchers/doublespeak/method_call'
require 'shoulda/matchers/doublespeak/object_double'
require 'shoulda/matchers/doublespeak/proxy_implementation'
require 'shoulda/matchers/doublespeak/stub_implementation'
require 'shoulda/matchers/doublespeak/world'
