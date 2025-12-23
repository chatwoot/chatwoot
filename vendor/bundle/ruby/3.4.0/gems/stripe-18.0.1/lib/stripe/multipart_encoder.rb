# frozen_string_literal: true

require "securerandom"
require "tempfile"

module Stripe
  # Encodes parameters into a `multipart/form-data` payload as described by RFC
  # 2388:
  #
  #     https://tools.ietf.org/html/rfc2388
  #
  # This is most useful for transferring file-like objects.
  #
  # Parameters should be added with `#encode`. When ready, use `#body` to get
  # the encoded result and `#content_type` to get the value that should be
  # placed in the `Content-Type` header of a subsequent request (which includes
  # a boundary value).
  class MultipartEncoder
    MULTIPART_FORM_DATA = "multipart/form-data"

    # A shortcut for encoding a single set of parameters and finalizing a
    # result.
    #
    # Returns an encoded body and the value that should be set in the content
    # type header of a subsequent request.
    def self.encode(params)
      encoder = MultipartEncoder.new
      encoder.encode(params)
      encoder.close
      [encoder.body, encoder.content_type]
    end

    # Gets the object's randomly generated boundary string.
    attr_reader :boundary

    # Initializes a new multipart encoder.
    def initialize
      # Kind of weird, but required by Rubocop because the unary plus operator
      # is considered faster than `Stripe.new`.
      @body = +""

      # Chose the same number of random bytes that Go uses in its standard
      # library implementation. Easily enough entropy to ensure that it won't
      # be present in a file we're sending.
      @boundary = SecureRandom.hex(30)

      @closed = false
      @first_field = true
    end

    # Gets the encoded body. `#close` must be called first.
    def body
      raise "object must be closed before getting body" unless @closed

      @body
    end

    # Finalizes the object by writing the final boundary.
    def close
      raise "object already closed" if @closed

      @body << "\r\n"
      @body << "--#{@boundary}--"

      @closed = true

      nil
    end

    # Gets the value including boundary that should be put into a multipart
    # request's `Content-Type`.
    def content_type
      "#{MULTIPART_FORM_DATA}; boundary=#{@boundary}"
    end

    # Encodes a set of parameters to the body.
    #
    # Note that parameters are expected to be a hash, but a "flat" hash such
    # that complex substructures like hashes and arrays have already been
    # appropriately Stripe-encoded. Pass a complex structure through
    # `Util.flatten_params` first before handing it off to this method.
    def encode(params)
      raise "no more parameters can be written to closed object" if @closed

      params.each do |name, val|
        if val.is_a?(::File) || val.is_a?(::Tempfile)
          write_field(name, val.read, filename: ::File.basename(val.path))
        elsif val.respond_to?(:read)
          write_field(name, val.read, filename: "blob")
        else
          write_field(name, val, filename: nil)
        end
      end

      nil
    end

    #
    # private
    #

    # Escapes double quotes so that the given value can be used in a
    # double-quoted string and replaces any linebreak characters with spaces.
    private def escape(str)
      str.gsub('"', "%22").tr("\n", " ").tr("\r", " ")
    end

    private def write_field(name, data, filename:)
      if @first_field
        @first_field = false
      else
        @body << "\r\n"
      end

      @body << "--#{@boundary}\r\n"

      if filename
        @body << (%(Content-Disposition: form-data) +
                 %(; name="#{escape(name.to_s)}") +
                 %(; filename="#{escape(filename)}"\r\n))
        @body << %(Content-Type: application/octet-stream\r\n)
      else
        @body << (%(Content-Disposition: form-data) +
                 %(; name="#{escape(name.to_s)}"\r\n))
      end

      @body << "\r\n"
      @body << data.to_s
    end
  end
end
