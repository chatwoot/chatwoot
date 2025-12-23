# frozen_string_literal: true

require 'digest'

module Datadog
  module Core
    module Remote
      class Configuration
        # Represent a list of Configuration::Digest
        class DigestList < Array
          class << self
            def parse(hash)
              new.concat(hash.map { |type, hexdigest| Digest.new(type, hexdigest) })
            end
          end

          def check(content)
            map { |digest| digest.check(content) }.reduce(:&)
          end
        end

        # Stores and validates different cryptographic hash functions
        class Digest
          class InvalidHashTypeError < StandardError; end
          attr_reader :type, :hexdigest

          DIGEST_CHUNK = 1024

          class << self
            def hexdigest(type, data)
              d = case type
              when :sha256
                ::Digest::SHA256.new
              when :sha512
                ::Digest::SHA512.new
              else
                raise InvalidHashTypeError, type
              end

              while (buf = data.read(DIGEST_CHUNK))
                d.update(buf)
              end

              d.hexdigest
            ensure
              data.rewind
            end
          end

          def initialize(type, hexdigest)
            @type = type.to_sym
            @hexdigest = hexdigest
          end

          def check(content)
            content.hexdigest(@type) == hexdigest
          end
        end
      end
    end
  end
end
