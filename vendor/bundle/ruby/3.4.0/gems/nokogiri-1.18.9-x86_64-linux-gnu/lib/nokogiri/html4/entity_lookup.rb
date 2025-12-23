# frozen_string_literal: true

module Nokogiri
  module HTML4
    class EntityDescription < Struct.new(:value, :name, :description); end

    class EntityLookup
      ###
      # Look up entity with +name+
      def [](name)
        (val = get(name)) && val.value
      end
    end
  end
end
