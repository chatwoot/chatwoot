# frozen_string_literal: true

require_relative "helpers/file"

module Byebug
  #
  # Represents a frame in the stack trace
  #
  class Frame
    include Helpers::FileHelper

    attr_reader :pos

    def initialize(context, pos)
      @context = context
      @pos = pos
    end

    def file
      @context.frame_file(pos)
    end

    def line
      @context.frame_line(pos)
    end

    def _self
      @context.frame_self(pos)
    end

    def _binding
      @context.frame_binding(pos)
    end

    def _class
      @context.frame_class(pos)
    end

    def _method
      @context.frame_method(pos)
    end

    def current?
      @context.frame.pos == pos
    end

    #
    # Gets local variables for the frame.
    #
    def locals
      return [] unless _binding

      _binding.local_variables.each_with_object({}) do |e, a|
        a[e] = _binding.local_variable_get(e)
        a
      end
    end

    #
    # Gets current method arguments for the frame.
    #
    def args
      return c_args unless _binding

      ruby_args
    end

    #
    # Returns the current class in the frame or an empty string if the current
    # +callstyle+ setting is 'short'
    #
    def deco_class
      Setting[:callstyle] == "short" || _class.to_s.empty? ? "" : "#{_class}."
    end

    def deco_block
      _method[/(?:block(?: \(\d+ levels\))?|rescue) in /] || ""
    end

    def deco_method
      _method[/((?:block(?: \(\d+ levels\))?|rescue) in )?(.*)/]
    end

    #
    # Builds a string containing all available args in the frame number, in a
    # verbose or non verbose way according to the value of the +callstyle+
    # setting
    #
    def deco_args
      return "" if args.empty?

      my_args = args.map do |arg|
        prefix, default = prefix_and_default(arg[0])

        kls = use_short_style?(arg) ? "" : "##{locals[arg[1]].class}"

        "#{prefix}#{arg[1] || default}#{kls}"
      end

      "(#{my_args.join(', ')})"
    end

    #
    # Builds a formatted string containing information about current method call
    #
    def deco_call
      deco_block + deco_class + deco_method + deco_args
    end

    #
    # Formatted filename in frame
    #
    def deco_file
      Setting[:fullpath] ? File.expand_path(file) : shortpath(file)
    end

    #
    # Properly formatted frame number of frame
    #
    def deco_pos
      format("%-2<pos>d", pos: pos)
    end

    #
    # Formatted mark for the frame.
    #
    # --> marks the current frame
    # ͱ-- marks c-frames
    #     marks regular frames
    #
    def mark
      return "-->" if current?
      return "    ͱ--" if c_frame?

      "   "
    end

    #
    # Checks whether the frame is a c-frame
    #
    def c_frame?
      _binding.nil?
    end

    def to_hash
      {
        mark: mark,
        pos: deco_pos,
        call: deco_call,
        file: deco_file,
        line: line,
        full_path: File.expand_path(deco_file)
      }
    end

    private

    def c_args
      return [] unless _self.to_s != "main"

      _class.instance_method(_method).parameters
    end

    def ruby_args
      meth_name = _binding.eval("__method__")
      return [] unless meth_name

      meth_obj = _class.instance_method(meth_name)
      return [] unless meth_obj

      meth_obj.parameters
    end

    def use_short_style?(arg)
      Setting[:callstyle] == "short" || arg[1].nil? || locals.empty?
    end

    def prefix_and_default(arg_type)
      return ["&", "block"] if arg_type == :block
      return ["*", "args"] if arg_type == :rest

      ["", nil]
    end
  end
end
