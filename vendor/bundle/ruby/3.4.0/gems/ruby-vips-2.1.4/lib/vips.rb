# This module provides an interface to the vips image processing library
# via ruby-ffi.
#
# Author::    John Cupitt  (mailto:jcupitt@gmail.com)
# License::   MIT

require "ffi"
require "logger"

# This module uses FFI to make a simple layer over the glib and gobject
# libraries.

# Generate a library name for ffi.
#
# Platform notes:
# linux:
#   Some distros allow "libvips.so", but only if the -dev headers have been
#   installed. To work everywhere, you must include the ABI number.
#   Confusingly, the file extension is not at the end. ffi adds the "lib"
#   prefix.
# mac:
#   As linux, but the extension is at the end and is added by ffi.
# windows:
#   The ABI number must be included, but with a hyphen. ffi does not add a
#   "lib" prefix or a ".dll" suffix.
def library_name(name, abi_number)
  if FFI::Platform.windows?
    "lib#{name}-#{abi_number}.dll"
  elsif FFI::Platform.mac?
    "#{name}.#{abi_number}"
  else
    "#{name}.so.#{abi_number}"
  end
end

module GLib
  class << self
    attr_accessor :logger
  end
  @logger = Logger.new($stdout)
  @logger.level = Logger::WARN

  extend FFI::Library

  ffi_lib library_name("glib-2.0", 0)

  attach_function :g_malloc, [:size_t], :pointer

  # save the FFI::Function that attach will return ... we can use it directly
  # as a param for callbacks
  G_FREE = attach_function :g_free, [:pointer], :void

  callback :g_log_func, [:string, :int, :string, :pointer], :void
  attach_function :g_log_set_handler,
    [:string, :int, :g_log_func, :pointer], :int
  attach_function :g_log_remove_handler, [:string, :int], :void

  # log flags
  LOG_FLAG_RECURSION = 1 << 0
  LOG_FLAG_FATAL = 1 << 1

  # GLib log levels
  LOG_LEVEL_ERROR = 1 << 2 # always fatal
  LOG_LEVEL_CRITICAL = 1 << 3
  LOG_LEVEL_WARNING = 1 << 4
  LOG_LEVEL_MESSAGE = 1 << 5
  LOG_LEVEL_INFO = 1 << 6
  LOG_LEVEL_DEBUG = 1 << 7

  # map glib levels to Logger::Severity
  GLIB_TO_SEVERITY = {
    LOG_LEVEL_ERROR => Logger::ERROR,
    LOG_LEVEL_CRITICAL => Logger::FATAL,
    LOG_LEVEL_WARNING => Logger::WARN,
    LOG_LEVEL_MESSAGE => Logger::UNKNOWN,
    LOG_LEVEL_INFO => Logger::INFO,
    LOG_LEVEL_DEBUG => Logger::DEBUG
  }
  GLIB_TO_SEVERITY.default = Logger::UNKNOWN

  # nil being the default
  @glib_log_domain = nil
  @glib_log_handler_id = 0

  # module-level, so it's not GCd away
  LOG_HANDLER = proc { |domain, level, message, _user_data|
    @logger.log(GLIB_TO_SEVERITY[level], message, domain)
  }

  def self.remove_log_handler
    if @glib_log_handler_id != 0 && @glib_log_domain
      g_log_remove_handler @glib_log_domain, @glib_log_handler_id
      @glib_log_handler_id = nil
    end
  end

  def self.set_log_domain domain
    GLib.remove_log_handler

    @glib_log_domain = domain

    # forward all glib logging output from this domain to a Ruby logger
    if @glib_log_domain
      # disable this feature for now
      #
      # libvips background worker threads can issue warnings, and
      # since the main thread is blocked waiting for libvips to come back
      # from an ffi call, you get a deadlock on the GIL
      #
      # to fix this, we need a way for g_log() calls from libvips workers
      # to be returned via the main thread
      #

      #             @glib_log_handler_id = g_log_set_handler @glib_log_domain,
      #                 LOG_LEVEL_DEBUG |
      #                 LOG_LEVEL_INFO |
      #                 LOG_LEVEL_MESSAGE |
      #                 LOG_LEVEL_WARNING |
      #                 LOG_LEVEL_ERROR |
      #                 LOG_LEVEL_CRITICAL |
      #                 LOG_FLAG_FATAL | LOG_FLAG_RECURSION,
      #                 LOG_HANDLER, nil

      # we must remove any handlers on exit, since libvips may log stuff
      # on shutdown and we don't want LOG_HANDLER to be invoked
      # after Ruby has gone
      at_exit {
        GLib.remove_log_handler
      }
    end
  end
end

module GObject
  extend FFI::Library

  ffi_lib library_name("gobject-2.0", 0)

  # we can't just use ulong, windows has different int sizing rules
  if FFI::Platform::ADDRESS_SIZE == 64
    typedef :uint64, :GType
  else
    typedef :uint32, :GType
  end

  attach_function :g_type_init, [], :void
  attach_function :g_type_name, [:GType], :string
  attach_function :g_type_from_name, [:string], :GType
  attach_function :g_type_fundamental, [:GType], :GType

  # glib before 2.36 needed this, does nothing in current glib
  g_type_init

  # look up some common gtypes
  GBOOL_TYPE = g_type_from_name "gboolean"
  GINT_TYPE = g_type_from_name "gint"
  GUINT64_TYPE = g_type_from_name "guint64"
  GDOUBLE_TYPE = g_type_from_name "gdouble"
  GENUM_TYPE = g_type_from_name "GEnum"
  GFLAGS_TYPE = g_type_from_name "GFlags"
  GSTR_TYPE = g_type_from_name "gchararray"
  GOBJECT_TYPE = g_type_from_name "GObject"
end

require "vips/gobject"
require "vips/gvalue"

# This module provides a binding for the [libvips image processing
# library](https://libvips.github.io/libvips/).
#
# # Example
#
# ```ruby
# require 'vips'
#
# if ARGV.length < 2
#     raise "usage: #{$PROGRAM_NAME}: input-file output-file"
# end
#
# im = Vips::Image.new_from_file ARGV[0], access: :sequential
#
# im *= [1, 2, 1]
#
# mask = Vips::Image.new_from_array [
#         [-1, -1, -1],
#         [-1, 16, -1],
#         [-1, -1, -1]
#        ], 8
# im = im.conv mask, precision: :integer
#
# im.write_to_file ARGV[1]
# ```
#
# This example loads a file, boosts the green channel (I'm not sure why),
# sharpens the image, and saves it back to disc again.
#
# Reading this example line by line, we have:
#
# ```ruby
# im = Vips::Image.new_from_file ARGV[0], access: :sequential
# ```
#
# {Image.new_from_file} can load any image file supported by vips. In this
# example, we will be accessing pixels top-to-bottom as we sweep through the
# image reading and writing, so `:sequential` access mode is best for us. The
# default mode is `:random`: this allows for full random access to image pixels,
# but is slower and needs more memory. See {Access}
# for full details
# on the various modes available.
#
# You can also load formatted images from memory buffers, create images that
# wrap C-style memory arrays, or make images from constants. Use {Source}
# and {Image.new_from_source} to load images from any data source, for
# example URIs.
#
# The next line:
#
# ```ruby
# im *= [1, 2, 1]
# ```
#
# Multiplying the image by an array constant uses one array element for each
# image band. This line assumes that the input image has three bands and will
# double the middle band. For RGB images, that's doubling green.
#
# Next we have:
#
# ```ruby
# mask = Vips::Image.new_from_array [
#         [-1, -1, -1],
#         [-1, 16, -1],
#         [-1, -1, -1]
#        ], 8
# im = im.conv mask, precision: :integer
# ```
#
# {Image.new_from_array} creates an image from an array constant. The 8 at
# the end sets the scale: the amount to divide the image by after
# integer convolution.
#
# See the libvips API docs for `vips_conv()` (the operation
# invoked by {Image#conv}) for details on the convolution operator. By default,
# it computes with a float mask, but `:integer` is fine for this case, and is
# much faster.
#
# Finally:
#
# ```ruby
# im.write_to_file ARGV[1]
# ```
#
# {Image#write_to_file} writes an image back to the filesystem. It can
# write any format supported by vips: the file type is set from the filename
# suffix. You can also write formatted images to memory buffers, or dump
# image data to a raw memory array.
#
# Use {Target} and {Image#write_to_target} to write formatted images to
# any data sink, for example URIs.
#
# # How it works
#
# The binding uses [ruby-ffi](https://github.com/ffi/ffi) to open the libvips
# shared library. When you call a method on the image class, it uses libvips
# introspection system (based on GObject) to search the
# library for an operation of that name, transforms the arguments to a form
# libvips can digest, and runs the operation.
#
# This means ruby-vips always presents the API implemented by the libvips shared
# library. It should update itself as new features are added.
#
# # Automatic wrapping
#
# `ruby-vips` adds a {Image.method_missing} handler to {Image} and uses
# it to look up vips operations. For example, the libvips operation `add`, which
# appears in C as `vips_add()`, appears in Ruby as {Image#add}.
#
# The operation's list of required arguments is searched and the first input
# image is set to the value of `self`. Operations which do not take an input
# image, such as {Image.black}, appear as class methods. The remainder of
# the arguments you supply in the function call are used to set the other
# required input arguments. Any trailing keyword arguments are used to set
# options on the operation.
#
# The result is the required output
# argument if there is only one result, or an array of values if the operation
# produces several results. If the operation has optional output objects, they
# are returned as a final hash.
#
# For example, {Image#min}, the vips operation that searches an image for
# the minimum value, has a large number of optional arguments. You can use it to
# find the minimum value like this:
#
# ```ruby
# min_value = image.min
# ```
#
# You can ask it to return the position of the minimum with `:x` and `:y`.
#
# ```ruby
# min_value, opts = min x: true, y: true
# x_pos = opts['x']
# y_pos = opts['y']
# ```
#
# Now `x_pos` and `y_pos` will have the coordinates of the minimum value.
# There's actually a convenience method for this, {Image#minpos}.
#
# You can also ask for the top *n* minimum, for example:
#
# ```ruby
# min_value, opts = min size: 10, x_array: true, y_array: true
# x_pos = opts['x_array']
# y_pos = opts['y_array']
# ```
#
# Now `x_pos` and `y_pos` will be 10-element arrays.
#
# Because operations are member functions and return the result image, you can
# chain them. For example, you can write:
#
# ```ruby
# result_image = image.real.cos
# ```
#
# to calculate the cosine of the real part of a complex image.
# There are also a full set
# of arithmetic operator overloads, see below.
#
# libvips types are also automatically wrapped. The override looks at the type
# of argument required by the operation and converts the value you supply,
# when it can. For example, {Image#linear} takes a `VipsArrayDouble` as
# an argument
# for the set of constants to use for multiplication. You can supply this
# value as an integer, a float, or some kind of compound object and it
# will be converted for you. You can write:
#
# ```ruby
# result_image = image.linear 1, 3
# result_image = image.linear 12.4, 13.9
# result_image = image.linear [1, 2, 3], [4, 5, 6]
# result_image = image.linear 1, [4, 5, 6]
# ```
#
# And so on. A set of overloads are defined for {Image#linear}, see below.
#
# It does a couple of more ambitious conversions. It will automatically convert
# to and from the various vips types, like `VipsBlob` and `VipsArrayImage`. For
# example, you can read the ICC profile out of an image like this:
#
# ```ruby
# profile = im.get_value "icc-profile-data"
# ```
#
# and profile will be a byte array.
#
# If an operation takes several input images, you can use a constant for all but
# one of them and the wrapper will expand the constant to an image for you. For
# example, {Image#ifthenelse} uses a condition image to pick pixels
# between a then and an else image:
#
# ```ruby
# result_image = condition_image.ifthenelse then_image, else_image
# ```
#
# You can use a constant instead of either the then or the else parts and it
# will be expanded to an image for you. If you use a constant for both then and
# else, it will be expanded to match the condition image. For example:
#
# ```ruby
# result_image = condition_image.ifthenelse [0, 255, 0], [255, 0, 0]
# ```
#
# Will make an image where true pixels are green and false pixels are red.
#
# This is useful for {Image#bandjoin}, the thing to join two or more
# images up bandwise. You can write:
#
# ```ruby
# rgba = rgb.bandjoin 255
# ```
#
# to append a constant 255 band to an image, perhaps to add an alpha channel. Of
# course you can also write:
#
# ```ruby
# result_image = image1.bandjoin image2
# result_image = image1.bandjoin [image2, image3]
# result_image = Vips::Image.bandjoin [image1, image2, image3]
# result_image = image1.bandjoin [image2, 255]
# ```
#
# and so on.
#
# # Logging
#
# Libvips uses g_log() to log warning, debug, info and (some) error messages.
#
# https://developer.gnome.org/glib/stable/glib-Message-Logging.html
#
# You can disable warnings by defining the `VIPS_WARNING` environment variable.
# You can enable info output by defining `VIPS_INFO`.
#
# # Exceptions
#
# The wrapper spots errors from vips operations and raises the {Vips::Error}
# exception. You can catch it in the usual way.
#
# # Automatic YARD documentation
#
# The bulk of these API docs are generated automatically by {Yard#generate}.
# It examines libvips and writes a summary of each operation and the arguments
# and options that that operation expects.
#
# Use the [C API # docs](https://libvips.github.io/libvips/API/current)
# for more detail.
#
# # Enums
#
# The libvips enums, such as `VipsBandFormat` appear in ruby-vips as Symbols
# like `:uchar`. They are documented as a set of classes for convenience, see
# {Vips::BandFormat}, for example.
#
# # Draw operations
#
# There are two ways of calling the libvips draw operations, like
# {Image#draw_circle} and {Image#draw_line}.
#
# First, you can use them like functions. For example:
#
# ```ruby
# y = x.draw_line 255, 0, 0, x.width, x.height
# ```
#
# This will make a new image, `y`, which is a copy of `x` but with a line
# drawn across it. `x` is unchanged.
#
# This is simple, but will be slow if you want to draw many lines, since
# ruby-vips will make a copy of the whole image each time.
#
# You can use {Image#mutate} to make a {MutableImage}. This is an image which
# is unshared and is only available inside the {Image#mutate} block. Within
# this block, you can use `!` versions of the draw operations to modify images
# and avoid the copy. For example:
#
# ```ruby
# image = image.mutate do |mutable|
#   (0 ... 1).step(0.01) do |i|
#     mutable.draw_line! 255, mutable.width * i, 0, 0, mutable.height * (1 - i)
#   end
# end
# ```
#
# Now each {Image#draw_line} will directly modify the mutable image, saving
# the copy. This is much faster and needs much less memory.
#
# # Metadata read
#
# Use {Image#get_fields} to get a list of the metadata fields that an image
# supports. ICC profiles, for example, are in a field called
# `icc-profile-data`. Use `vipsheader -a something.jpg` at the command-line
# to see all the fields on an image.
#
# Use {Image#get_typeof} to get the type of a field. Types are integers, with
# 0 meaning "no such field". Constants like {GObject::GINT_TYPE} are useful for
# testing field types.
#
# You can read image metadata using {Image#get}. The field value is converted
# to a Ruby value in the obvious way.
#
# # Metadata write
#
# You can also set and remove image metadata fields. Images are immutable, so
# you must make any changes inside a {Image#mutate} block. For example:
#
# ```ruby
# image = image.mutate do |mutable|
#   image.get_fields.each do |field|
#     mutable.remove! field unless field == "icc-profile-data"
#   end
# end
# ```
#
# To remove all metadata except the icc profile.
#
# You can use {MutableImage#set!} to change the value of an existing field,
# and {MutableImage#set_type!} to create a new field with a specified type.
#
# # Progress
#
# You can attach signal handlers to images to watch computation progress. For
# example:
#
# ```ruby
# image = Vips::Image.black 1, 100000
# image.set_progress true
#
# def progress_to_s(name, progress)
#   puts "#{name}:"
#   puts "    run = #{progress[:run]}"
#   puts "    eta = #{progress[:eta]}"
#   puts "    tpels = #{progress[:tpels]}"
#   puts "    npels = #{progress[:npels]}"
#   puts "    percent = #{progress[:percent]}"
# end
#
# image.signal_connect :preeval do |progress|
#   progress_to_s("preeval", progress)
# end
#
# image.signal_connect :eval do |progress|
#   progress_to_s("eval", progress)
#   image.set_kill(true) if progress[:percent] > 50
# end
#
# image.signal_connect :posteval do |progress|
#   progress_to_s("posteval", progress)
# end
#
# image.avg
# ```
#
# The `:eval` signal will fire for every tile that is processed. You can stop
# progress with {Image#set_kill} and processing will end with an exception.
#
# User streams
#
# You can make your own input and output stream objects with {SourceCustom} and
# {TargetCustom}. For example:
#
# ```ruby
# file = File.open "some/file", "rb"
# source = Vips::SourceCustom.new
# source.on_read { |length| file.read length }
# image = Vips::Image.new_from_source source, "", access: "sequential"
# ```
#
# # Overloads
#
# The wrapper defines the usual set of arithmetic, boolean and relational
# overloads on image. You can mix images, constants and lists of constants
# (almost) freely. For example, you can write:
#
# ```ruby
# result_image = ((image * [1, 2, 3]).abs < 128) | 4
# ```
#
# # Expansions
#
# Some vips operators take an enum to select an action, for example
# {Image#math} can be used to calculate sine of every pixel like this:
#
# ```ruby
# result_image = image.math :sin
# ```
#
# This is annoying, so the wrapper expands all these enums into separate members
# named after the enum. So you can write:
#
# ```ruby
# result_image = image.sin
# ```
#
# # Convenience functions
#
# The wrapper defines a few extra useful utility functions:
# {Image#get_value}, {Image#set_value}, {Image#bandsplit},
# {Image#maxpos}, {Image#minpos},
# {Image#median}.

module Vips
  extend FFI::Library

  ffi_lib library_name("vips", 42)

  LOG_DOMAIN = "VIPS"
  GLib.set_log_domain LOG_DOMAIN

  # we can't just use ulong, windows has different int sizing rules
  if FFI::Platform::ADDRESS_SIZE == 64
    typedef :uint64, :GType
  else
    typedef :uint32, :GType
  end

  attach_function :vips_error_buffer, [], :string
  attach_function :vips_error_clear, [], :void
  attach_function :vips_error_freeze, [], :void
  attach_function :vips_error_thaw, [], :void

  # The ruby-vips error class.
  class Error < RuntimeError
    # @param msg [String] The error message. If this is not supplied, grab
    #   and clear the vips error buffer and use that.
    def initialize msg = nil
      if msg
        @details = msg
      elsif Vips.vips_error_buffer != ""
        @details = Vips.vips_error_buffer
        Vips.vips_error_clear
      else
        @details = nil
      end
    end

    # Pretty-print a {Vips::Error}.
    #
    # @return [String] The error message
    def to_s
      if !@details.nil?
        @details
      else
        super.to_s
      end
    end
  end

  attach_function :vips_init, [:string], :int

  if Vips.vips_init($0) != 0
    throw Vips.get_error
  end

  # don't use at_exit to call vips_shutdown, it causes problems with fork, and
  # in any case libvips does this for us

  attach_function :vips_leak_set, [:int], :void
  attach_function :vips_vector_set_enabled, [:int], :void
  attach_function :vips_concurrency_set, [:int], :void

  # vips_foreign_get_suffixes was added in libvips 8.8
  begin
    attach_function :vips_foreign_get_suffixes, [], :pointer
  rescue FFI::NotFoundError
    nil
  end

  # Turn libvips leak testing on and off. Handy for debugging ruby-vips, not
  # very useful for user code.
  def self.leak_set leak
    vips_leak_set((leak ? 1 : 0))
  end

  attach_function :vips_cache_set_max, [:int], :void
  attach_function :vips_cache_set_max_mem, [:int], :void
  attach_function :vips_cache_set_max_files, [:int], :void

  # Set the maximum number of operations that libvips should cache. Set 0 to
  # disable the operation cache. The default is 1000.
  def self.cache_set_max size
    vips_cache_set_max size
  end

  # Set the maximum amount of memory that libvips should use for the operation
  # cache. Set 0 to disable the operation cache. The default is 100mb.
  def self.cache_set_max_mem size
    vips_cache_set_max_mem size
  end

  # Set the maximum number of files libvips should keep open in the
  # operation cache. Set 0 to disable the operation cache. The default is
  # 100.
  def self.cache_set_max_files size
    vips_cache_set_max_files size
  end

  # Set the size of the libvips worker pool. This defaults to the number of
  # hardware threads on your computer. Set to 1 to disable threading.
  def self.concurrency_set n
    vips_concurrency_set n
  end

  # Enable or disable SIMD and the run-time compiler. This can give a nice
  # speed-up, but can also be unstable on some systems or with some versions
  # of the run-time compiler.
  def self.vector_set enabled
    vips_vector_set_enabled(enabled ? 1 : 0)
  end

  # Deprecated compatibility function.
  #
  # Don't use this, instead change GLib::logger.level.
  def self.set_debug debug
    if debug
      GLib.logger.level = Logger::DEBUG
    end
  end

  attach_function :version, :vips_version, [:int], :int
  attach_function :version_string, :vips_version_string, [], :string

  # True if this is at least libvips x.y
  def self.at_least_libvips?(x, y)
    major = version(0)
    minor = version(1)

    major > x || (major == x && minor >= y)
  end

  # Get a list of all supported file suffixes.
  #
  # @return [[String]] array of supported suffixes
  def self.get_suffixes
    # vips_foreign_get_suffixes() was added in libvips 8.8
    return [] unless Vips.respond_to? :vips_foreign_get_suffixes

    array = Vips.vips_foreign_get_suffixes

    names = []
    p = array
    until (q = p.read_pointer).null?
      suff = q.read_string
      GLib.g_free q
      names << suff unless names.include? suff
      p += FFI::Type::POINTER.size
    end
    GLib.g_free array

    names
  end

  LIBRARY_VERSION = Vips.version_string

  # libvips has this arbitrary number as a sanity-check upper bound on image
  # size. It's sometimes useful to know when calculating scale factors.
  MAX_COORD = 10000000
end

require "vips/object"
require "vips/operation"
require "vips/image"
require "vips/mutableimage"
require "vips/interpolate"
require "vips/region"
require "vips/version"
require "vips/connection"
require "vips/source"
require "vips/sourcecustom"
require "vips/target"
require "vips/targetcustom"
