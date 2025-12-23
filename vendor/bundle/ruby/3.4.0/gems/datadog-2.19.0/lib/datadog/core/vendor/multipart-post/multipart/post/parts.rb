#--
# Copyright (c) 2007-2013 Nick Sieger.
# See the file README.txt included with the distribution for
# software license details.
#++

module Datadog
  module Core
    module Vendor
      module Multipart
        module Post
          module Parts
            module Part
              def self.new(boundary, name, value, headers = {})
                headers ||= {} # avoid nil values
                if file?(value)
                  FilePart.new(boundary, name, value, headers)
                else
                  ParamPart.new(boundary, name, value, headers)
                end
              end

              def self.file?(value)
                value.respond_to?(:content_type) && value.respond_to?(:original_filename)
              end

              def length
                @part.length
              end

              def to_io
                @io
              end
            end

            # Represents a parametric part to be filled with given value.
            class ParamPart
              include Part

              # @param boundary [String]
              # @param name [#to_s]
              # @param value [String]
              # @param headers [Hash] Content-Type and Content-ID are used, if present.
              def initialize(boundary, name, value, headers = {})
                @part = build_part(boundary, name, value, headers)
                @io = StringIO.new(@part)
              end

              def length
                @part.bytesize
              end

              # @param boundary [String]
              # @param name [#to_s]
              # @param value [String]
              # @param headers [Hash] Content-Type is used, if present.
              def build_part(boundary, name, value, headers = {})
                part = ''
                part << "--#{boundary}\r\n"
                part << "Content-ID: #{headers["Content-ID"]}\r\n" if headers["Content-ID"]
                part << "Content-Disposition: form-data; name=\"#{name}\"\r\n"
                part << "Content-Type: #{headers["Content-Type"]}\r\n" if headers["Content-Type"]
                part << "\r\n"
                part << "#{value}\r\n"
              end
            end

            # Represents a part to be filled from file IO.
            class FilePart
              include Part

              attr_reader :length

              # @param boundary [String]
              # @param name [#to_s]
              # @param io [IO]
              # @param headers [Hash]
              def initialize(boundary, name, io, headers = {})
                file_length = io.respond_to?(:length) ? io.length : File.size(io.local_path)
                @head = build_head(boundary, name, io.original_filename, io.content_type, file_length,
                  io.respond_to?(:opts) ? io.opts.merge(headers) : headers)
                @foot = "\r\n"
                @length = @head.bytesize + file_length + @foot.length
                @io = CompositeReadIO.new(StringIO.new(@head), io, StringIO.new(@foot))
              end

              # @param boundary [String]
              # @param name [#to_s]
              # @param filename [String]
              # @param type [String]
              # @param content_len [Integer]
              # @param opts [Hash]
              def build_head(boundary, name, filename, type, content_len, opts = {})
                opts = opts.clone

                trans_encoding = opts.delete("Content-Transfer-Encoding") || "binary"
                content_disposition = opts.delete("Content-Disposition") || "form-data"

                part = ''
                part << "--#{boundary}\r\n"
                part << "Content-Disposition: #{content_disposition}; name=\"#{name}\"; filename=\"#{filename}\"\r\n"
                part << "Content-Length: #{content_len}\r\n"
                if content_id = opts.delete("Content-ID")
                  part << "Content-ID: #{content_id}\r\n"
                end

                part << if !opts["Content-Type"].nil?
                  "Content-Type: " + opts["Content-Type"] + "\r\n"
                else
                  "Content-Type: #{type}\r\n"
                end

                part << "Content-Transfer-Encoding: #{trans_encoding}\r\n"

                opts.each do |k, v|
                  part << "#{k}: #{v}\r\n"
                end

                part << "\r\n"
              end
            end

            # Represents the epilogue or closing boundary.
            class EpiloguePart
              include Part

              def initialize(boundary)
                @part = "--#{boundary}--\r\n"
                @io = StringIO.new(@part)
              end
            end
          end
        end
      end
    end
  end
end
