# frozen_string_literal: true

require 'tempfile'
require 'fileutils'

module Rack
  module Multipart
    # Despite the misleading name, UploadedFile is designed for use for
    # preparing multipart file upload bodies, generally for use in tests.
    # It is not designed for and should not be used for handling uploaded
    # files (there is no need for that, since Rack's multipart parser
    # already creates Tempfiles for that). Using this with non-trusted
    # filenames can create a security vulnerability.
    #
    # You should only use this class if you plan on passing the instances
    # to Rack::MockRequest for use in creating multipart request bodies.
    #
    # UploadedFile delegates most methods to the tempfile it contains.
    class UploadedFile
      # The provided name of the file. This generally is the basename of
      # path provided during initialization, but it can contain slashes if they
      # were present in the filename argument when the instance was created.
      attr_reader :original_filename

      # The content type of the instance.
      attr_accessor :content_type

      # Create a new UploadedFile.  For backwards compatibility, this accepts
      # both positional and keyword versions of the same arguments:
      #
      # filepath/path :: The path to the file
      # ct/content_type :: The content_type of the file
      # bin/binary :: Whether to set binmode on the file before copying data into it.
      #
      # If both positional and keyword arguments are present, the keyword arguments
      # take precedence.
      #
      # The following keyword-only arguments are also accepted:
      #
      # filename :: Override the filename to use for the file.  This is so the
      #             filename for the upload does not need to match the basename of
      #             the file path.  This should not contain slashes, unless you are
      #             trying to test how an application handles invalid filenames in
      #             multipart upload bodies.
      # io :: Use the given IO-like instance as the tempfile, instead of creating
      #       a Tempfile instance.  This is useful for building multipart file
      #       upload bodies without a file being present on the filesystem. If you are
      #       providing this, you should also provide the filename argument.
      def initialize(filepath = nil, ct = "text/plain", bin = false,
                     path: filepath, content_type: ct, binary: bin, filename: nil, io: nil)
        if io
          @tempfile = io
          @original_filename = filename
        else
          raise "#{path} file does not exist" unless ::File.exist?(path)
          @original_filename = filename || ::File.basename(path)
          @tempfile = Tempfile.new([@original_filename, ::File.extname(path)], encoding: Encoding::BINARY)
          @tempfile.binmode if binary
          FileUtils.copy_file(path, @tempfile.path)
        end
        @content_type = content_type
      end

      # The path of the tempfile for the instance, if the tempfile has a path.
      # nil if the tempfile does not have a path.
      def path
        @tempfile.path if @tempfile.respond_to?(:path)
      end
      alias_method :local_path, :path

      # Return true if the tempfile responds to the method.
      def respond_to_missing?(*args)
        @tempfile.respond_to?(*args)
      end

      # Delegate method missing calls to the tempfile.
      def method_missing(method_name, *args, &block) #:nodoc:
        @tempfile.__send__(method_name, *args, &block)
      end
    end
  end
end
