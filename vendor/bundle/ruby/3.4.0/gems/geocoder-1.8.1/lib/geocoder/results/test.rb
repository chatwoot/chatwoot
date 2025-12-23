require 'geocoder/results/base'

module Geocoder
  module Result
    class Test < Base

      def self.add_result_attribute(attr)
        begin
          remove_method(attr) if method_defined?(attr)
        rescue NameError # method defined on superclass
        end

        define_method(attr) do
          @data[attr.to_s] || @data[attr.to_sym]
        end
      end

      %w[coordinates neighborhood city state state_code sub_state
      sub_state_code province province_code postal_code country
      country_code address street_address street_number route geometry].each do |attr|
        add_result_attribute(attr)
      end

      def initialize(data)
        data.each_key do |attr|
          Test.add_result_attribute(attr)
        end

        super
      end
    end
  end
end
