# frozen_string_literal: true

module Loofah
  module MetaHelpers # :nodoc:
    class << self
      def add_downcased_set_members_to_all_set_constants(mojule)
        mojule.constants.each do |constant_sym|
          constant = mojule.const_get(constant_sym)
          next unless Set === constant

          constant.dup.each do |member|
            constant.add(member.downcase)
          end
        end
      end
    end
  end
end
