# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2008, by McClain Looney.
# Copyright, 2008-2013, by Nick Sieger.
# Copyright, 2011, by Gerrit Riessen.
# Copyright, 2013, by Vincent Pellé.
# Copyright, 2013, by Gustav Ernberg.
# Copyright, 2013, by Socrates Vicente.
# Copyright, 2013, by Steffen Grunwald.
# Copyright, 2019, by Olle Jonsson.
# Copyright, 2019-2022, by Samuel Williams.
# Copyright, 2019, by Patrick Davey.
# Copyright, 2022, by Jason York.

require_relative 'parts'
require_relative 'composite_read_io'

require 'securerandom'

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

      def initialize(path, params, headers={}, boundary = Multipartable.secure_boundary)
        headers = headers.clone # don't want to modify the original variable
        parts_headers = symbolize_keys(headers.delete(:parts) || {})

        super(path, headers)
        parts = symbolize_keys(params).map do |k,v|
          case v
          when Array
            v.map {|item| Parts::Part.new(boundary, k, item, parts_headers[k]) }
          else
            Parts::Part.new(boundary, k, v, parts_headers[k])
          end
        end.flatten
        parts << Parts::EpiloguePart.new(boundary)
        ios = parts.map {|p| p.to_io }
        self.set_content_type(headers["Content-Type"] || "multipart/form-data",
                              { "boundary" => boundary })
        self.content_length = parts.inject(0) {|sum,i| sum + i.length }
        self.body_stream = CompositeReadIO.new(*ios)

        @boundary = boundary
      end

      attr :boundary

      private

      if RUBY_VERSION >= "2.5.0"
        def symbolize_keys(hash)
          hash.transform_keys(&:to_sym)
        end
      else
        def symbolize_keys(hash)
          hash.map{|key,value| [key.to_sym, value]}.to_h
        end
      end
    end
  end
end
