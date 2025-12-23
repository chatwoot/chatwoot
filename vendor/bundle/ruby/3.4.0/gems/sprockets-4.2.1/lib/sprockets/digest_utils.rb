# frozen_string_literal: true
require 'digest/sha1'
require 'digest/sha2'
require 'set'

module Sprockets
  # Internal: Hash functions and digest related utilities. Mixed into
  # Environment.
  module DigestUtils
    extend self

    # Internal: Default digest class.
    #
    # Returns a Digest::Base subclass.
    def digest_class
      Digest::SHA256
    end

    # Internal: Maps digest bytesize to the digest class.
    DIGEST_SIZES = {
      20 => Digest::SHA1,
      32 => Digest::SHA256,
      48 => Digest::SHA384,
      64 => Digest::SHA512
    }

    # Internal: Detect digest class hash algorithm for digest bytes.
    #
    # While not elegant, all the supported digests have a unique bytesize.
    #
    # Returns Digest::Base or nil.
    def detect_digest_class(bytes)
      DIGEST_SIZES[bytes.bytesize]
    end

    ADD_VALUE_TO_DIGEST = {
      String     => ->(val, digest) { digest << val },
      FalseClass => ->(val, digest) { digest << 'FalseClass'.freeze },
      TrueClass  => ->(val, digest) { digest << 'TrueClass'.freeze  },
      NilClass   => ->(val, digest) { digest << 'NilClass'.freeze   },

      Symbol => ->(val, digest) {
        digest << 'Symbol'.freeze
        digest << val.to_s
      },
      Integer => ->(val, digest) {
        digest << 'Integer'.freeze
        digest << val.to_s
      },
      Array => ->(val, digest) {
        digest << 'Array'.freeze
        val.each do |element|
          ADD_VALUE_TO_DIGEST[element.class].call(element, digest)
        end
      },
      Hash => ->(val, digest) {
        digest << 'Hash'.freeze
        val.sort.each do |array|
          ADD_VALUE_TO_DIGEST[Array].call(array, digest)
        end
      },
      Set => ->(val, digest) {
        digest << 'Set'.freeze
        ADD_VALUE_TO_DIGEST[Array].call(val, digest)
      },
      Encoding => ->(val, digest) {
        digest << 'Encoding'.freeze
        digest << val.name
      }
    }

    ADD_VALUE_TO_DIGEST.compare_by_identity.rehash

    ADD_VALUE_TO_DIGEST.default_proc = ->(_, val) {
      raise TypeError, "couldn't digest #{ val }"
    }
    private_constant :ADD_VALUE_TO_DIGEST

    # Internal: Generate a hexdigest for a nested JSON serializable object.
    #
    # This is used for generating cache keys, so its pretty important its
    # wicked fast. Microbenchmarks away!
    #
    # obj - A JSON serializable object.
    #
    # Returns a String digest of the object.
    def digest(obj)
      build_digest(obj).digest
    end

    # Internal: Generate a hexdigest for a nested JSON serializable object.
    #
    # The same as `pack_hexdigest(digest(obj))`.
    #
    # obj - A JSON serializable object.
    #
    # Returns a String digest of the object.
    def hexdigest(obj)
      build_digest(obj).hexdigest!
    end

    # Internal: Pack a binary digest to a hex encoded string.
    #
    # bin - String bytes
    #
    # Returns hex String.
    def pack_hexdigest(bin)
      bin.unpack('H*'.freeze).first
    end

    # Internal: Unpack a hex encoded digest string into binary bytes.
    #
    # hex - String hex
    #
    # Returns binary String.
    def unpack_hexdigest(hex)
      [hex].pack('H*')
    end

    # Internal: Pack a binary digest to a base64 encoded string.
    #
    # bin - String bytes
    #
    # Returns base64 String.
    def pack_base64digest(bin)
      [bin].pack('m0')
    end

    # Internal: Pack a binary digest to a urlsafe base64 encoded string.
    #
    # bin - String bytes
    #
    # Returns urlsafe base64 String.
    def pack_urlsafe_base64digest(bin)
      str = pack_base64digest(bin)
      str.tr!('+/'.freeze, '-_'.freeze)
      str.tr!('='.freeze, ''.freeze)
      str
    end

    # Internal: Maps digest class to the CSP hash algorithm name.
    HASH_ALGORITHMS = {
      Digest::SHA256 => 'sha256'.freeze,
      Digest::SHA384 => 'sha384'.freeze,
      Digest::SHA512 => 'sha512'.freeze
    }

    # Public: Generate hash for use in the `integrity` attribute of an asset tag
    # as per the subresource integrity specification.
    #
    # digest - The String byte digest of the asset content.
    #
    # Returns a String or nil if hash algorithm is incompatible.
    def integrity_uri(digest)
      case digest
      when Digest::Base
        digest_class = digest.class
        digest = digest.digest
      when String
        digest_class = DIGEST_SIZES[digest.bytesize]
      else
        raise TypeError, "unknown digest: #{digest.inspect}"
      end

      if hash_name = HASH_ALGORITHMS[digest_class]
        "#{hash_name}-#{pack_base64digest(digest)}"
      end
    end

    # Public: Generate hash for use in the `integrity` attribute of an asset tag
    # as per the subresource integrity specification.
    #
    # digest - The String hexbyte digest of the asset content.
    #
    # Returns a String or nil if hash algorithm is incompatible.
    def hexdigest_integrity_uri(hexdigest)
      integrity_uri(unpack_hexdigest(hexdigest))
    end

    # Internal: Checks an asset name for a valid digest
    #
    # name - The name of the asset
    #
    # Returns true if the name contains a digest like string and .digested before the extension
    def already_digested?(name)
      return name =~ /-([0-9a-zA-Z]{7,128})\.digested/
    end

    private
      def build_digest(obj)
        digest = digest_class.new

        ADD_VALUE_TO_DIGEST[obj.class].call(obj, digest)
        digest
      end
  end
end
