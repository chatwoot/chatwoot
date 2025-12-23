# frozen_string_literal: true

require_relative 'multipart_boundary'

module HTTParty
  class Request
    class Body
      NEWLINE = "\r\n"
      private_constant :NEWLINE

      def initialize(params, query_string_normalizer: nil, force_multipart: false)
        @params = params
        @query_string_normalizer = query_string_normalizer
        @force_multipart = force_multipart
      end

      def call
        if params.respond_to?(:to_hash)
          multipart? ? generate_multipart : normalize_query(params)
        else
          params
        end
      end

      def boundary
        @boundary ||= MultipartBoundary.generate
      end

      def multipart?
        params.respond_to?(:to_hash) && (force_multipart || has_file?(params))
      end

      private

      # https://html.spec.whatwg.org/#multipart-form-data
      MULTIPART_FORM_DATA_REPLACEMENT_TABLE = {
        '"'  => '%22',
        "\r" => '%0D',
        "\n" => '%0A'
      }.freeze

      def generate_multipart
        normalized_params = params.flat_map { |key, value| HashConversions.normalize_keys(key, value) }

        multipart = normalized_params.inject(''.dup) do |memo, (key, value)|
          memo << "--#{boundary}#{NEWLINE}"
          memo << %(Content-Disposition: form-data; name="#{key}")
          # value.path is used to support ActionDispatch::Http::UploadedFile
          # https://github.com/jnunemaker/httparty/pull/585
          memo << %(; filename="#{file_name(value).gsub(/["\r\n]/, MULTIPART_FORM_DATA_REPLACEMENT_TABLE)}") if file?(value)
          memo << NEWLINE
          memo << "Content-Type: #{content_type(value)}#{NEWLINE}" if file?(value)
          memo << NEWLINE
          memo << content_body(value)
          memo << NEWLINE
        end

        multipart << "--#{boundary}--#{NEWLINE}"
      end

      def has_file?(value)
        if value.respond_to?(:to_hash)
          value.to_hash.any? { |_, v| has_file?(v) }
        elsif value.respond_to?(:to_ary)
          value.to_ary.any? { |v| has_file?(v) }
        else
          file?(value)
        end
      end

      def file?(object)
        object.respond_to?(:path) && object.respond_to?(:read)
      end

      def normalize_query(query)
        if query_string_normalizer
          query_string_normalizer.call(query)
        else
          HashConversions.to_params(query)
        end
      end

      def content_body(object)
        if file?(object)
          object = (file = object).read
          file.rewind if file.respond_to?(:rewind)
        end

        object.to_s
      end

      def content_type(object)
        return object.content_type if object.respond_to?(:content_type)
        mime = MiniMime.lookup_by_filename(object.path)
        mime ? mime.content_type : 'application/octet-stream'
      end

      def file_name(object)
        object.respond_to?(:original_filename) ? object.original_filename : File.basename(object.path)
      end

      attr_reader :params, :query_string_normalizer, :force_multipart
    end
  end
end
