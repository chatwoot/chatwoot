# frozen_string_literal: true

require 'erb'

module Datadog
  module Tracing
    module Contrib
      module Propagation
        module SqlComment
          # To be prepended to a sql statement.
          class Comment
            def initialize(hash)
              @hash = hash
            end

            def to_s
              @string ||= begin
                ret = String.new

                @hash.each do |key, value|
                  next if value.nil?

                  # Url encode
                  value = ERB::Util.url_encode(value)

                  # Escape SQL
                  ret << "#{key}='#{value}',"
                end

                # Remove the last `,`
                ret.chop!

                "/*#{ret}*/"
              end
            end
          end
        end
      end
    end
  end
end
