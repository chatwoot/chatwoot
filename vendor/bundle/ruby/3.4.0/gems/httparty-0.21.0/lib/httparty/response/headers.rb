# frozen_string_literal: true

require 'delegate'

module HTTParty
  class Response #:nodoc:
    class Headers < ::SimpleDelegator
      include ::Net::HTTPHeader

      def initialize(header_values = nil)
        @header = {}
        if header_values
          header_values.each_pair do |k,v|
            if v.is_a?(Array)
              v.each do |sub_v|
                add_field(k, sub_v)
              end
            else
              add_field(k, v)
            end
          end
        end
        super(@header)
      end

      def ==(other)
        if other.is_a?(::Net::HTTPHeader)
          @header == other.instance_variable_get(:@header)
        elsif other.is_a?(Hash)
          @header == other || @header == Headers.new(other).instance_variable_get(:@header)
        end
      end
    end
  end
end
