module Shoulda
  module Matchers
    module ActiveModel
      # @private
      module Qualifiers
      end
    end
  end
end

require_relative 'qualifiers/allow_nil'
require_relative 'qualifiers/allow_blank'
require_relative 'qualifiers/ignore_interference_by_writer'
require_relative 'qualifiers/ignoring_interference_by_writer'
