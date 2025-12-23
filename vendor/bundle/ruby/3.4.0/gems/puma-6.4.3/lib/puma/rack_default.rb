# frozen_string_literal: true

require_relative '../rack/handler/puma'

# rackup was removed in Rack 3, it is now a separate gem
if Object.const_defined? :Rackup
  module Rackup
    module Handler
      def self.default(options = {})
        ::Rackup::Handler::Puma
      end
    end
  end
elsif Object.const_defined?(:Rack) && Rack.release < '3'
  module Rack
    module Handler
      def self.default(options = {})
        ::Rack::Handler::Puma
      end
    end
  end
else
  raise "Rack 3 must be used with the Rackup gem"
end
