module ScoutApm
  module Utils
    class UniqueId
      ALPHABET = ('a'..'z').to_a.freeze

      def self.simple(length=16)
        s = ""
        length.times do
            s << ALPHABET[rand(26)]
        end
        s
      end
    end

    # Represents a random ID that we can use to track a certain transaction.
    # The `trans` prefix is only for ease of reading logs - it should not be
    # interpreted to convey any sort of meaning.
    class TransactionId
      def initialize
        @random = SecureRandom.hex(16)
      end

      def to_s
        "trans-#{@random}"
      end
    end

    # Represents a random ID that we can use to track a certain span. The
    # `span` prefix is only for ease of reading logs - it should not be
    # interpreted to convey any sort of meaning.
    class SpanId
      def initialize
        @random = SecureRandom.hex(16)
      end

      def to_s
        "span-#{@random}"
      end
    end

  end
end
