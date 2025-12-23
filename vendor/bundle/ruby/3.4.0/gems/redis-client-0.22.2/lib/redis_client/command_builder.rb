# frozen_string_literal: true

class RedisClient
  module CommandBuilder
    extend self

    if Symbol.method_defined?(:name)
      def generate(args, kwargs = nil)
        command = args.flat_map do |element|
          case element
          when Hash
            element.flatten
          else
            element
          end
        end

        kwargs&.each do |key, value|
          if value
            if value == true
              command << key.name
            else
              command << key.name << value
            end
          end
        end

        command.map! do |element|
          case element
          when String
            element
          when Symbol
            element.name
          when Integer, Float
            element.to_s
          else
            raise TypeError, "Unsupported command argument type: #{element.class}"
          end
        end

        if command.empty?
          raise ArgumentError, "can't issue an empty redis command"
        end

        command
      end
    else
      def generate(args, kwargs = nil)
        command = args.flat_map do |element|
          case element
          when Hash
            element.flatten
          else
            element
          end
        end

        kwargs&.each do |key, value|
          if value
            if value == true
              command << key.to_s
            else
              command << key.to_s << value
            end
          end
        end

        command.map! do |element|
          case element
          when String
            element
          when Integer, Float, Symbol
            element.to_s
          else
            raise TypeError, "Unsupported command argument type: #{element.class}"
          end
        end

        if command.empty?
          raise ArgumentError, "can't issue an empty redis command"
        end

        command
      end
    end
  end
end
