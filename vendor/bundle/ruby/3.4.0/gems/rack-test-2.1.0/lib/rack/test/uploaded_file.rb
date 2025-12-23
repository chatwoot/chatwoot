# frozen_string_literal: true

require 'fileutils'
require 'tempfile'
require 'stringio'

module Rack
  module Test
    # Wraps a Tempfile with a content type. Including one or more UploadedFile's
    # in the params causes Rack::Test to build and issue a multipart request.
    #
    # Example:
    #   post "/photos", "file" => Rack::Test::UploadedFile.new("me.jpg", "image/jpeg")
    class UploadedFile
      # The filename, *not* including the path, of the "uploaded" file
      attr_reader :original_filename

      # The tempfile
      attr_reader :tempfile

      # The content type of the "uploaded" file
      attr_accessor :content_type

      # Creates a new UploadedFile instance.
      #
      # Arguments:
      # content :: is a path to a file, or an {IO} or {StringIO} object representing the content.
      # content_type :: MIME type of the file
      # binary :: Whether the file should be set to binmode (content treated as binary).
      # original_filename :: The filename to use for the file. Required if content is StringIO, optional override if not
      def initialize(content, content_type = 'text/plain', binary = false, original_filename: nil)
        @content_type = content_type
        @original_filename = original_filename

        case content
        when StringIO
          initialize_from_stringio(content)
        else
          initialize_from_file_path(content)
        end

        @tempfile.binmode if binary
      end

      # The path to the tempfile. Will not work if the receiver's content is from a StringIO.
      def path
        tempfile.path
      end
      alias local_path path

      # Delegate all methods not handled to the tempfile.
      def method_missing(method_name, *args, &block)
        tempfile.public_send(method_name, *args, &block)
      end

      # Append to given buffer in 64K chunks to avoid multiple large
      # copies of file data in memory.  Rewind tempfile before and
      # after to make sure all data in tempfile is appended to the
      # buffer.
      def append_to(buffer)
        tempfile.rewind

        buf = String.new
        buffer << tempfile.readpartial(65_536, buf) until tempfile.eof?

        tempfile.rewind

        nil
      end

      def respond_to_missing?(method_name, include_private = false) #:nodoc:
        tempfile.respond_to?(method_name, include_private) || super
      end

      # A proc that can be used as a finalizer to close and unlink the tempfile.
      def self.finalize(file)
        proc { actually_finalize file }
      end

      # Close and unlink the given file, used as a finalizer for the tempfile,
      # if the tempfile is backed by a file in the filesystem.
      def self.actually_finalize(file)
        file.close
        file.unlink
      end

      private

      # Use the StringIO as the tempfile.
      def initialize_from_stringio(stringio)
        raise(ArgumentError, 'Missing `original_filename` for StringIO object') unless @original_filename

        @tempfile = stringio
      end

      # Create a tempfile and copy the content from the given path into the tempfile, optionally renaming if
      # original_filename has been set.
      def initialize_from_file_path(path)
        raise "#{path} file does not exist" unless ::File.exist?(path)

        @original_filename ||= ::File.basename(path)
        extension = ::File.extname(@original_filename)

        @tempfile = Tempfile.new([::File.basename(@original_filename, extension), extension])
        @tempfile.set_encoding(Encoding::BINARY)

        ObjectSpace.define_finalizer(self, self.class.finalize(@tempfile))

        FileUtils.copy_file(path, @tempfile.path)
      end
    end
  end
end
