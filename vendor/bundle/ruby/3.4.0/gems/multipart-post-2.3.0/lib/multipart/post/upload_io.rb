# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022, by Samuel Williams.

module Multipart
  module Post
    # Convenience methods for dealing with files and IO that are to be uploaded.
    class UploadIO
      attr_reader :content_type, :original_filename, :local_path, :io, :opts

      # Create an upload IO suitable for including in the params hash of a
      # Net::HTTP::Post::Multipart.
      #
      # Can take two forms. The first accepts a filename and content type, and
      # opens the file for reading (to be closed by finalizer).
      #
      # The second accepts an already-open IO, but also requires a third argument,
      # the filename from which it was opened (particularly useful/recommended if
      # uploading directly from a form in a framework, which often save the file to
      # an arbitrarily named RackMultipart file in /tmp).
      #
      # @example
      #     UploadIO.new("file.txt", "text/plain")
      #     UploadIO.new(file_io, "text/plain", "file.txt")
      def initialize(filename_or_io, content_type, filename = nil, opts = {})
        io = filename_or_io
        local_path = ""
        if io.respond_to? :read
          # in Ruby 1.9.2, StringIOs no longer respond to path
          # (since they respond to :length, so we don't need their local path, see parts.rb:41)
          local_path = filename_or_io.respond_to?(:path) ? filename_or_io.path : "local.path"
        else
          io = File.open(filename_or_io)
          local_path = filename_or_io
        end
        filename ||= local_path

        @content_type = content_type
        @original_filename = File.basename(filename)
        @local_path = local_path
        @io = io
        @opts = opts
      end

      def self.convert!(io, content_type, original_filename, local_path)
        raise ArgumentError, "convert! has been removed. You must now wrap IOs " \
          "using:\nUploadIO.new(filename_or_io, content_type, " \
          "filename=nil)\nPlease update your code."
      end

      def method_missing(*args)
        @io.send(*args)
      end

      def respond_to?(meth, include_all = false)
        @io.respond_to?(meth, include_all) || super(meth, include_all)
      end
    end
  end
end

UploadIO = Multipart::Post::UploadIO
Object.deprecate_constant :UploadIO
