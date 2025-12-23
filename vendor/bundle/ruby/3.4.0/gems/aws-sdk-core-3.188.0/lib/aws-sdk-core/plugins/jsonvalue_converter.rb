# frozen_string_literal: true

module Aws
  module Plugins

    # Converts input value to JSON Syntax for members with jsonvalue trait
    class JsonvalueConverter < Seahorse::Client::Plugin

      # @api private
      class Handler < Seahorse::Client::Handler

        def call(context)
          context.operation.input.shape.members.each do |m, ref|
            convert_jsonvalue(m, ref, context.params, 'params')
          end
          @handler.call(context)
        end

        def convert_jsonvalue(m, ref, params, context)
          return if params.nil? || !params.key?(m)

          if ref['jsonvalue']
            params[m] = serialize_jsonvalue(params[m], "#{context}[#{m}]")
          else
            case ref.shape
            when Seahorse::Model::Shapes::StructureShape
              ref.shape.members.each do |member_m, ref|
                convert_jsonvalue(member_m, ref, params[m], "#{context}[#{m}]")
              end
            when Seahorse::Model::Shapes::ListShape
              if ref.shape.member['jsonvalue']
                params[m] = params[m].each_with_index.map do |v, i|
                  serialize_jsonvalue(v, "#{context}[#{m}][#{i}]")
                end
              end
            when Seahorse::Model::Shapes::MapShape
              if ref.shape.value['jsonvalue']
                params[m].each do |k, v|
                  params[m][k] = serialize_jsonvalue(v, "#{context}[#{m}][#{k}]")
                end
              end
            end
          end
        end

        def serialize_jsonvalue(v, context)
          unless v.respond_to?(:to_json)
            raise ArgumentError, "The value of #{context} is not JSON serializable."
          end
          v.to_json
        end

      end

      handler(Handler, step: :initialize)
    end

  end
end
