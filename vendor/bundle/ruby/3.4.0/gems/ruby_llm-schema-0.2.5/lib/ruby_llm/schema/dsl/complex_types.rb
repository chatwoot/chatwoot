# frozen_string_literal: true

module RubyLLM
  class Schema
    module DSL
      module ComplexTypes
        def object(name, description: nil, required: true, **options, &block)
          add_property(name, object_schema(description: description, **options, &block), required: required)
        end

        def array(name, description: nil, required: true, **options, &block)
          add_property(name, array_schema(description: description, **options, &block), required: required)
        end

        def any_of(name, description: nil, required: true, **options, &block)
          add_property(name, any_of_schema(description: description, **options, &block), required: required)
        end

        def one_of(name, description: nil, required: true, **options, &block)
          add_property(name, one_of_schema(description: description, **options, &block), required: required)
        end

        def optional(name, description: nil, &block)
          any_of(name, description: description) do
            instance_eval(&block)
            null
          end
        end
      end
    end
  end
end
