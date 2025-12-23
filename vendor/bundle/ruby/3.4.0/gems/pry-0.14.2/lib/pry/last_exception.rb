# frozen_string_literal: true

#
# {Pry::LastException} is a proxy class who wraps an Exception object for
# {Pry#last_exception}. it extends the exception object with methods that
# help pry commands be useful.
#
# the original exception object is not modified and method calls are forwarded
# to the wrapped exception object.
#
class Pry
  class LastException < BasicObject
    attr_accessor :bt_index

    def initialize(exception)
      @exception = exception
      @bt_index = 0
      @file, @line = bt_source_location_for(0)
    end

    def method_missing(name, *args, &block)
      if @exception.respond_to?(name)
        @exception.public_send(name, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(name, include_all = false)
      @exception.respond_to?(name, include_all)
    end

    #
    # @return [String]
    #  returns the path to a file for the current backtrace. see {#bt_index}.
    #
    attr_reader :file

    #
    # @return [Fixnum]
    #  returns the line for the current backtrace. see {#bt_index}.
    #
    attr_reader :line

    # @return [Exception]
    #   returns the wrapped exception
    #
    def wrapped_exception
      @exception
    end

    def bt_source_location_for(index)
      backtrace[index] =~ /(.*):(\d+)/
      [::Regexp.last_match(1), ::Regexp.last_match(2).to_i]
    end

    def inc_bt_index
      @bt_index = (@bt_index + 1) % backtrace.size
    end
  end
end
