# frozen_string_literal: true

module Declarative
  def self.Inspect(obj)
    string = obj.inspect

    if obj.is_a?(Proc)
      elements = string.split('/')
      string = "#{elements.first}#{elements.last}"
    end
    string.gsub(/0x\w+/, '')
  end

  module Inspect
    def inspect
      string = super
      if is_a?(Proc)
        elements = string.split('/')
        string = "#{elements.first}#{elements.last}"
      end
      string.gsub(/0x\w+/, '')
    end

    module Schema
      def inspect
        definitions.extend(Definitions::Inspect)
        "Schema: #{definitions.inspect}"
      end
    end
  end

  module Definitions::Inspect
    def inspect
      each do |dfn|
        dfn.extend(Declarative::Inspect)

        if dfn[:nested]&.is_a?(Declarative::Schema::DSL)
          dfn[:nested].extend(Declarative::Inspect::Schema)
        else
          dfn[:nested]&.extend(Declarative::Definitions::Inspect)
        end
      end
      super
    end

    def get(*)
      super.extend(Declarative::Inspect)
    end
  end
end
