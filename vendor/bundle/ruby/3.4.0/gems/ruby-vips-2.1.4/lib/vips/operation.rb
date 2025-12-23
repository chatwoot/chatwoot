# This module provides an interface to the top level bits of libvips
# via ruby-ffi.
#
# Author::    John Cupitt  (mailto:jcupitt@gmail.com)
# License::   MIT

require "ffi"
require "set"

module Vips
  private

  attach_function :vips_operation_new, [:string], :pointer

  # We may well block during this (eg. if it's avg, or perhaps jpegsave), and
  # libvips might trigger some signals which ruby has handles for.
  #
  # We need FFI to drop the GIL lock during this call and reacquire it when
  # the call ends, or we'll deadlock.
  attach_function :vips_cache_operation_build, [:pointer], :pointer,
    blocking: true
  attach_function :vips_object_unref_outputs, [:pointer], :void

  callback :argument_map_fn, [:pointer,
    GObject::GParamSpec.ptr,
    ArgumentClass.ptr,
    ArgumentInstance.ptr,
    :pointer, :pointer], :pointer
  attach_function :vips_argument_map, [:pointer,
    :argument_map_fn,
    :pointer, :pointer], :pointer

  OPERATION_SEQUENTIAL = 1
  OPERATION_NOCACHE = 4
  OPERATION_DEPRECATED = 8

  OPERATION_FLAGS = {
    sequential: OPERATION_SEQUENTIAL,
    nocache: OPERATION_NOCACHE,
    deprecated: OPERATION_DEPRECATED
  }

  attach_function :vips_operation_get_flags, [:pointer], :int

  # Introspect a vips operation and return a large structure containing
  # everything we know about it. This is used for doc generation as well as
  # call.
  class Introspect
    attr_reader :name, :description, :flags, :args, :required_input,
      :optional_input, :required_output, :optional_output, :member_x,
      :method_args, :vips_name, :destructive, :doc_optional_input,
      :doc_optional_output

    @@introspect_cache = {}

    def initialize name
      # if there's a trailing "!", this is a destructive version of an
      # operation
      if name[-1] == "!"
        @destructive = true
        # strip the trailing "!"
        @vips_name = name[0...-1]
      else
        @destructive = false
        @vips_name = name
      end

      @op = Operation.new @vips_name
      @args = []
      @required_input = []
      @optional_input = {}
      @required_output = []
      @optional_output = {}

      # find all the arguments the operator can take
      @op.argument_map do |pspec, argument_class, _argument_instance|
        flags = argument_class[:flags]
        if (flags & ARGUMENT_CONSTRUCT) != 0
          # names can include - as punctuation, but we always use _ in
          # Ruby
          arg_name = pspec[:name].tr("-", "_")
          @args << {
            arg_name: arg_name,
            flags: flags,
            gtype: pspec[:value_type]
          }
        end

        nil
      end

      @args.each do |details|
        arg_name = details[:arg_name]
        flags = details[:flags]

        if (flags & ARGUMENT_INPUT) != 0
          if (flags & ARGUMENT_REQUIRED) != 0 &&
              (flags & ARGUMENT_DEPRECATED) == 0
            @required_input << details
          else
            # we allow deprecated optional args
            @optional_input[arg_name] = details
          end

          # MODIFY INPUT args count as OUTPUT as well in non-destructive mode
          if (flags & ARGUMENT_MODIFY) != 0 &&
              !@destructive
            if (flags & ARGUMENT_REQUIRED) != 0 &&
                (flags & ARGUMENT_DEPRECATED) == 0
              @required_output << details
            else
              @optional_output[arg_name] = details
            end
          end
        elsif (flags & ARGUMENT_OUTPUT) != 0
          if (flags & ARGUMENT_REQUIRED) != 0 &&
              (flags & ARGUMENT_DEPRECATED) == 0
            @required_output << details
          else
            # again, allow deprecated optional args
            @optional_output[arg_name] = details
          end
        end
      end

      # in destructive mode, the first required input arg must be MODIFY and
      # must be an image
      if @destructive
        if @required_input.length < 1 ||
            @required_input[0][:flags] & ARGUMENT_MODIFY == 0 ||
            @required_input[0][:gtype] != IMAGE_TYPE
          raise Vips::Error, "operation #{@vips_name} is not destructive"
        end
      end
    end

    # Yard comment generation needs a little more introspection. We add this
    # extra metadata in a separate method to keep the main path as fast as
    # we can.
    def add_yard_introspection name
      @name = name
      @description = Vips.vips_object_get_description @op
      @flags = Vips.vips_operation_get_flags @op
      @member_x = nil
      @method_args = []
      @doc_optional_input = {}
      @doc_optional_output = {}

      @args.each do |details|
        arg_name = details[:arg_name]
        flags = details[:flags]
        gtype = details[:gtype]

        details[:yard_name] = arg_name == "in" ? "im" : arg_name
        pspec = @op.get_pspec arg_name
        details[:blurb] = GObject.g_param_spec_get_blurb pspec

        if (flags & ARGUMENT_INPUT) != 0 &&
            (flags & ARGUMENT_REQUIRED) != 0 &&
            (flags & ARGUMENT_DEPRECATED) == 0
          # the first required input image is the thing we will be a method
          # of
          if @member_x.nil? && gtype == IMAGE_TYPE
            @member_x = details
          else
            @method_args << details
          end
        end
      end

      # and make the arg sets to document by filtering out deprecated args
      @optional_input.each do |arg_name, details|
        next if (details[:flags] & ARGUMENT_DEPRECATED) != 0
        @doc_optional_input[details[:arg_name]] = details
      end

      @optional_output.each do |arg_name, details|
        next if (details[:flags] & ARGUMENT_DEPRECATED) != 0
        @doc_optional_output[details[:arg_name]] = details
      end
    end

    def self.get name
      @@introspect_cache[name] ||= Introspect.new name
    end

    def self.get_yard name
      introspect = Introspect.get name
      introspect.add_yard_introspection name
      introspect
    end
  end

  class Operation < Object
    # the layout of the VipsOperation struct
    module OperationLayout
      def self.included base
        base.class_eval do
          layout :parent, Object::Struct
          # rest opaque
        end
      end
    end

    class Struct < Object::Struct
      include OperationLayout
    end

    class ManagedStruct < Object::ManagedStruct
      include OperationLayout
    end

    def initialize value
      # allow init with a pointer so we can wrap the return values from
      # things like _build
      if value.is_a? String
        value = Vips.vips_operation_new value
        raise Vips::Error if value.null?
      end

      super value
    end

    def build
      op = Vips.vips_cache_operation_build self
      if op.null?
        Vips.vips_object_unref_outputs self
        raise Vips::Error
      end

      Operation.new op
    end

    def argument_map &block
      fn = proc do |_op, pspec, argument_class, argument_instance, _a, _b|
        block.call pspec, argument_class, argument_instance
      end
      Vips.vips_argument_map self, fn, nil, nil
    end

    # Search an object for the first element to match a predicate. Search
    # inside subarrays and sub-hashes. Equlvalent to x.flatten.find{}.
    def self.flat_find object, &block
      if object.respond_to? :each
        object.each do |x|
          result = flat_find x, &block
          return result unless result.nil?
        end
      elsif yield object
        return object
      end

      nil
    end

    # expand a constant into an image
    def self.imageize match_image, value
      return value if value.is_a?(Image) || value.is_a?(MutableImage)

      # 2D array values become tiny 2D images
      # if there's nothing to match to, we also make a 2D image
      if (value.is_a?(Array) && value[0].is_a?(Array)) || match_image.nil?
        Image.new_from_array value
      else
        # we have a 1D array ... use that as a pixel constant and
        # expand to match match_image
        match_image.new_from_image value
      end
    end

    # set an operation argument, expanding constants and copying images as
    # required
    def set name, value, match_image, flags, gtype, destructive
      if gtype == IMAGE_TYPE
        value = Operation.imageize match_image, value

        # in non-destructive mode, make sure we have a unique copy
        if (flags & ARGUMENT_MODIFY) != 0 &&
            !destructive
          value = value.copy.copy_memory
        end
      elsif gtype == ARRAY_IMAGE_TYPE
        value = value.map { |x| Operation.imageize match_image, x }
      end

      super name, value
    end

    public

    # This is the public entry point for the vips binding. {call} will run
    # any vips operation, for example:
    #
    # ```ruby
    # out = Vips::Operation.call "black", [100, 100], {:bands => 12}
    # ```
    #
    # will call the C function
    #
    # ```C
    # vips_black( &out, 100, 100, "bands", 12, NULL );
    # ```
    #
    # There are {Image#method_missing} hooks which will run {call} for you
    # on {Image} for undefined instance or class methods. So you can also
    # write:
    #
    # ```ruby
    # out = Vips::Image.black 100, 100, bands: 12
    # ```
    #
    # Or perhaps:
    #
    # ```ruby
    # x = Vips::Image.black 100, 100
    # y = x.invert
    # ```
    #
    # to run the `vips_invert()` operator.
    #
    # There are also a set of operator overloads and some convenience
    # functions, see {Image}.
    #
    # If the operator needs a vector constant, {call} will turn a scalar
    # into a
    # vector for you. So for `x.linear a, b`, which calculates
    # `x * a + b` where `a` and `b` are vector constants, you can write:
    #
    # ```ruby
    # x = Vips::Image.black 100, 100, bands: 3
    # y = x.linear 1, 2
    # y = x.linear [1], 4
    # y = x.linear [1, 2, 3], 4
    # ```
    #
    # or any other combination. The operator overloads use this facility to
    # support all the variations on:
    #
    # ```ruby
    # x = Vips::Image.black 100, 100, bands: 3
    # y = x * 2
    # y = x + [1,2,3]
    # y = x % [1]
    # ```
    #
    # Similarly, wherever an image is required, you can use a constant. The
    # constant will be expanded to an image matching the first input image
    # argument. For example, you can write:
    #
    # ```
    # x = Vips::Image.black 100, 100, bands: 3
    # y = x.bandjoin 255
    # ```
    #
    # to add an extra band to the image where each pixel in the new band has
    # the constant value 255.

    def self.call name, supplied, optional = {}, option_string = ""
      GLib.logger.debug("Vips::VipsOperation.call") {
        "name = #{name}, supplied = #{supplied}, " \
          "optional = #{optional}, option_string = #{option_string}"
      }

      introspect = Introspect.get name
      required_input = introspect.required_input
      required_output = introspect.required_output
      optional_input = introspect.optional_input
      optional_output = introspect.optional_output
      destructive = introspect.destructive

      unless supplied.is_a? Array
        raise Vips::Error, "unable to call #{name}: " \
          "argument array is not an array"
      end
      unless optional.is_a? Hash
        raise Vips::Error, "unable to call #{name}: " \
          "optional arguments are not a hash"
      end

      if supplied.length != required_input.length
        raise Vips::Error, "unable to call #{name}: " \
          "you supplied #{supplied.length} arguments, " \
          "but operation needs #{required_input.length}."
      end

      # all supplied_optional keys should be in optional_input or
      # optional_output
      optional.each do |key, _value|
        arg_name = key.to_s

        unless optional_input.has_key?(arg_name) ||
            optional_output.has_key?(arg_name)
          raise Vips::Error, "unable to call #{name}: " \
            "unknown option #{arg_name}"
        end
      end

      # the first image arg is the thing we expand constants to match ...
      # we need to find it
      #
      # look inside array and hash arguments, since we may be passing an
      # array of images
      #
      # also enforce the rules around mutable and non-mutable images
      match_image = nil
      flat_find(supplied) do |value|
        if match_image
          # no non-first image arg can ever be mutable
          if value.is_a?(MutableImage)
            raise Vips::Error, "unable to call #{name}: " \
              "only the first image argument can be mutable"
          end
        elsif destructive
          if value.is_a?(Image)
            raise Vips::Error, "unable to call #{name}: " \
              "first image argument to a destructive " \
              "operation must be mutable"
          elsif value.is_a?(MutableImage)
            match_image = value
          end
        elsif value.is_a?(MutableImage)
          # non destructive operation, so no mutable images
          raise Vips::Error, "unable to call #{name}: " \
            "must not pass mutable images to " \
            "non-destructive operations"
        elsif value.is_a?(Image)
          match_image = value
        end

        # keep looping
        false
      end

      op = Operation.new introspect.vips_name

      # set any string args first so they can't be overridden
      unless option_string.nil?
        if Vips.vips_object_set_from_string(op, option_string) != 0
          raise Vips::Error
        end
      end

      # collect a list of all input references here
      references = Set.new

      add_reference = lambda do |x|
        if x.is_a?(Vips::Image)
          x.references.each do |i|
            references << i
          end
        end
        false
      end

      # set all required inputs
      required_input.each_index do |i|
        details = required_input[i]
        arg_name = details[:arg_name]
        flags = details[:flags]
        gtype = details[:gtype]
        value = supplied[i]

        flat_find value, &add_reference
        op.set arg_name, value, match_image, flags, gtype, destructive
      end

      # set all optional inputs
      optional.each do |key, value|
        next if value.nil?

        arg_name = key.to_s

        if optional_input.has_key? arg_name
          details = optional_input[arg_name]
          flags = details[:flags]
          gtype = details[:gtype]

          flat_find value, &add_reference
          op.set arg_name, value, match_image, flags, gtype, destructive
        end
      end

      op = op.build

      # attach all input refs to output x
      set_reference = lambda do |x|
        if x.is_a? Vips::Image
          x.references += references
        end
        false
      end

      # get all required results
      result = []
      required_output.each do |details|
        value = details[:arg_name]
        flat_find value, &set_reference
        result << op.get(value)
      end

      # fetch all optional ones
      optional_results = {}
      optional.each do |key, _value|
        arg_name = key.to_s

        if optional_output.has_key? arg_name
          value = op.get arg_name
          flat_find value, &set_reference
          optional_results[arg_name] = value
        end
      end

      result << optional_results if optional_results != {}

      if result.length == 1
        result = result.first
      elsif result.length == 0
        result = nil
      end

      GLib.logger.debug("Vips::Operation.call") { "result = #{result}" }

      Vips.vips_object_unref_outputs op

      result
    end
  end
end
