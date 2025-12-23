require 'brakeman/util'

module Brakeman
  class MethodInfo
    include Brakeman::Util

    attr_reader :name, :src, :owner, :file, :type

    def initialize name, src, owner, file
      @name = name
      @src = src
      @owner = owner
      @file = file
      @type = case src.node_type
              when :defn
                :instance
              when :defs
                :class
              else
                raise "Expected sexp type: #{src.node_type}"
              end

      @simple_method = nil
    end

    # To support legacy code that expected a Hash
    def [] attr
      self.send(attr)
    end

    def very_simple_method?
      return @simple_method == :very unless @simple_method.nil?

      # Very simple methods have one (simple) expression in the body and
      # no arguments
      if src.formal_args.length == 1 # no args
        if src.method_length == 1 # Single expression in body
          value = first_body # First expression in body

          if simple_literal? value or
              (array? value and all_literals? value) or
              (hash? value and all_literals? value, :hash)

            @return_value = value
            @simple_method = :very
          end
        end
      end

      @simple_method ||= false
    end

    def return_value env = nil
      if very_simple_method?
        return @return_value
      else
        nil
      end
    end

    def first_body
      case @type
      when :class
        src[4]
      when :instance
        src[3]
      end
    end
  end
end
