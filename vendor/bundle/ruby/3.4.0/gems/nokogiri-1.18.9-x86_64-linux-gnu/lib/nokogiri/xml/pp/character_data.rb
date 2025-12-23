# frozen_string_literal: true

module Nokogiri
  module XML
    # :nodoc: all
    module PP
      module CharacterData
        def pretty_print(pp)
          nice_name = self.class.name.split("::").last
          pp.group(2, "#(#{nice_name} ", ")") do
            pp.pp(text)
          end
        end

        def inspect
          "#<#{self.class.name}:#{format("0x%x", object_id)} #{text.inspect}>"
        end
      end
    end
  end
end
