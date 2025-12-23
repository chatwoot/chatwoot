require 'active_support/message_verifier'
require 'time'

class SignedGlobalID < GlobalID
  class ExpiredMessage < StandardError; end

  class << self
    attr_accessor :verifier, :expires_in

    def parse(sgid, options = {})
      super verify(sgid.to_s, options), options
    end

    # Grab the verifier from options and fall back to SignedGlobalID.verifier.
    # Raise ArgumentError if neither is available.
    def pick_verifier(options)
      options.fetch :verifier do
        verifier || raise(ArgumentError, 'Pass a `verifier:` option with an `ActiveSupport::MessageVerifier` instance, or set a default SignedGlobalID.verifier.')
      end
    end

    DEFAULT_PURPOSE = "default"

    def pick_purpose(options)
      options.fetch :for, DEFAULT_PURPOSE
    end

    private
      def verify(sgid, options)
        verify_with_verifier_validated_metadata(sgid, options) ||
          verify_with_legacy_self_validated_metadata(sgid, options)
      end

      def verify_with_verifier_validated_metadata(sgid, options)
        pick_verifier(options).verify(sgid, purpose: pick_purpose(options))
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        nil
      end

      def verify_with_legacy_self_validated_metadata(sgid, options)
        metadata = pick_verifier(options).verify(sgid)

        raise_if_expired(metadata['expires_at'])

        metadata['gid'] if pick_purpose(options)&.to_s == metadata['purpose']&.to_s
      rescue ActiveSupport::MessageVerifier::InvalidSignature, ExpiredMessage
        nil
      end

      def raise_if_expired(expires_at)
        if expires_at && Time.now.utc > Time.iso8601(expires_at)
          raise ExpiredMessage, 'This signed global id has expired.'
        end
      end
  end

  attr_reader :verifier, :purpose, :expires_at

  def initialize(gid, options = {})
    super
    @verifier = self.class.pick_verifier(options)
    @purpose = self.class.pick_purpose(options)
    @expires_at = pick_expiration(options)
  end

  def to_s
    @sgid ||= @verifier.generate(@uri.to_s, purpose: purpose, expires_at: expires_at)
  end
  alias to_param to_s

  def ==(other)
    super && @purpose == other.purpose
  end

  def inspect # :nodoc:
    "#<#{self.class.name}:#{'%#016x' % (object_id << 1)}>"
  end

  private
    def pick_expiration(options)
      return options[:expires_at] if options.key?(:expires_at)

      if expires_in = options.fetch(:expires_in) { self.class.expires_in }
        expires_in.from_now
      end
    end
end
