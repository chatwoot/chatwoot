#--
# Copyright (c) 2007-2013 Nick Sieger.
# See the file README.txt included with the distribution for
# software license details.
#++

require_relative 'parts'
require_relative 'composite_read_io'
require 'securerandom'

module Datadog
  module Core
    module Vendor
      module Multipart
        module Post
          module Multipartable
            def self.secure_boundary
              # https://tools.ietf.org/html/rfc7230
              #      tchar          = "!" / "#" / "$" / "%" / "&" / "'" / "*"
              #                     / "+" / "-" / "." / "^" / "_" / "`" / "|" / "~"
              #                     / DIGIT / ALPHA

              # https://tools.ietf.org/html/rfc2046
              #      bcharsnospace := DIGIT / ALPHA / "'" / "(" / ")" /
              #                       "+" / "_" / "," / "-" / "." /
              #                       "/" / ":" / "=" / "?"

              "--#{SecureRandom.uuid}"
            end

            def initialize(path, params, headers = {}, boundary = Multipartable.secure_boundary)
              headers = headers.clone # don't want to modify the original variable
              parts_headers = headers.delete(:parts) || {}
              super(path, headers)
              parts = params.map do |k, v|
                case v
                when Array
                  v.map { |item| Parts::Part.new(boundary, "#{k}[]", item, parts_headers[k]) }
                else
                  Parts::Part.new(boundary, k, v, parts_headers[k])
                end
              end.flatten
              parts << Parts::EpiloguePart.new(boundary)
              ios = parts.map { |p| p.to_io }
              set_content_type(headers["Content-Type"] || "multipart/form-data",
                {"boundary" => boundary})
              self.content_length = parts.inject(0) { |sum, i| sum + i.length }
              self.body_stream = CompositeReadIO.new(*ios)

              @boundary = boundary
            end

            attr_reader :boundary
          end
        end
      end
    end
  end
end
