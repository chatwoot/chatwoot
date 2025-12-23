require "uber/callable"

module Uber
  class Option
    def self.[](value, options={}) # TODO: instance_exec: true
      if value.is_a?(Proc)
        return ->(context, *args) { context.instance_exec(*args, &value) } if options[:instance_exec]
        return value
      end

      return value                                            if value.is_a?(Uber::Callable)
      return ->(context, *args){ context.send(value, *args) } if value.is_a?(Symbol)
      ->(*) { value }
    end
  end
end
