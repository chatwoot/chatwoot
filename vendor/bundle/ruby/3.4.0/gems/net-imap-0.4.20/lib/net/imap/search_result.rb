# frozen_string_literal: true

module Net
  class IMAP

    # An array of sequence numbers returned by Net::IMAP#search, or unique
    # identifiers returned by Net::IMAP#uid_search.
    #
    # For backward compatibility, SearchResult inherits from Array.
    class SearchResult < Array

      # Returns a SearchResult populated with the given +seq_nums+.
      #
      #     Net::IMAP::SearchResult[1, 3, 5, modseq: 9]
      #     # => Net::IMAP::SearchResult[1, 3, 5, modseq: 9]
      def self.[](*seq_nums, modseq: nil)
        new(seq_nums, modseq: modseq)
      end

      # A modification sequence number, as described by the +CONDSTORE+
      # extension in {[RFC7162
      # §3.1.6]}[https://www.rfc-editor.org/rfc/rfc7162.html#section-3.1.6].
      attr_reader :modseq

      # Returns a SearchResult populated with the given +seq_nums+.
      #
      #     Net::IMAP::SearchResult.new([1, 3, 5], modseq: 9)
      #     # => Net::IMAP::SearchResult[1, 3, 5, modseq: 9]
      def initialize(seq_nums, modseq: nil)
        super(seq_nums.to_ary.map { Integer _1 })
        @modseq = Integer modseq if modseq
      end

      # Returns whether +other+ is a SearchResult with the same values and the
      # same #modseq.  The order of numbers is irrelevant.
      #
      #     Net::IMAP::SearchResult[123, 456, modseq: 789] ==
      #       Net::IMAP::SearchResult[123, 456, modseq: 789]
      #     # => true
      #     Net::IMAP::SearchResult[123, 456, modseq: 789] ==
      #       Net::IMAP::SearchResult[456, 123, modseq: 789]
      #     # => true
      #
      #     Net::IMAP::SearchResult[123, 456, modseq: 789] ==
      #       Net::IMAP::SearchResult[987, 654, modseq: 789]
      #     # => false
      #     Net::IMAP::SearchResult[123, 456, modseq: 789] ==
      #       Net::IMAP::SearchResult[1, 2, 3, modseq: 9999]
      #     # => false
      #
      # SearchResult can be compared directly with Array, if #modseq is nil and
      # the array is sorted.
      #
      #     Net::IMAP::SearchResult[9, 8, 6, 4, 1] == [1, 4, 6, 8, 9] # => true
      #     Net::IMAP::SearchResult[3, 5, 7, modseq: 99] == [3, 5, 7] # => false
      #
      # Note that Array#== does require matching order and ignores #modseq.
      #
      #     [9, 8, 6, 4, 1] == Net::IMAP::SearchResult[1, 4, 6, 8, 9] # => false
      #     [3, 5, 7] == Net::IMAP::SearchResult[3, 5, 7, modseq: 99] # => true
      #
      def ==(other)
        (modseq ?
         other.is_a?(self.class) && modseq == other.modseq :
         other.is_a?(Array)) &&
          size == other.size &&
          sort == other.sort
      end

      # Hash equality.  Unlike #==, order will be taken into account.
      def hash
        return super if modseq.nil?
        [super, self.class, modseq].hash
      end

      # Hash equality.  Unlike #==, order will be taken into account.
      def eql?(other)
        return super if modseq.nil?
        self.class == other.class && hash == other.hash
      end

      # Returns a string that represents the SearchResult.
      #
      #    Net::IMAP::SearchResult[123, 456, 789].inspect
      #    # => "[123, 456, 789]"
      #
      #    Net::IMAP::SearchResult[543, 210, 678, modseq: 2048].inspect
      #    # => "Net::IMAP::SearchResult[543, 210, 678, modseq: 2048]"
      #
      def inspect
        return super if modseq.nil?
        "%s[%s, modseq: %p]" % [self.class, join(", "), modseq]
      end

      # Returns a string that follows the formal \IMAP syntax.
      #
      #    data = Net::IMAP::SearchResult[2, 8, 32, 128, 256, 512]
      #    data.to_s           # => "* SEARCH 2 8 32 128 256 512"
      #    data.to_s("SEARCH") # => "* SEARCH 2 8 32 128 256 512"
      #    data.to_s("SORT")   # => "* SORT 2 8 32 128 256 512"
      #    data.to_s(nil)      # => "2 8 32 128 256 512"
      #
      #    data = Net::IMAP::SearchResult[1, 3, 16, 1024, modseq: 2048].to_s
      #    data.to_s           # => "* SEARCH 1 3 16 1024 (MODSEQ 2048)"
      #    data.to_s("SORT")   # => "* SORT 1 3 16 1024 (MODSEQ 2048)"
      #    data.to_s           # => "1 3 16 1024 (MODSEQ 2048)"
      #
      def to_s(type = "SEARCH")
        str = +""
        str << "* %s " % [type.to_str] unless type.nil?
        str << join(" ")
        str << " (MODSEQ %d)" % [modseq] if modseq
        -str
      end

      # Converts the SearchResult into a SequenceSet.
      #
      #     Net::IMAP::SearchResult[9, 1, 2, 4, 10, 12, 3, modseq: 123_456]
      #       .to_sequence_set
      #     # => Net::IMAP::SequenceSet["1:4,9:10,12"]
      def to_sequence_set; SequenceSet[*self] end

      def pretty_print(pp)
        return super if modseq.nil?
        pp.text self.class.name + "["
        pp.group_sub do
          pp.nest(2) do
            pp.breakable ""
            each do |num|
              pp.pp num
              pp.text ","
              pp.fill_breakable
            end
            pp.breakable ""
            pp.text "modseq: "
            pp.pp modseq
          end
          pp.breakable ""
          pp.text "]"
        end
      end

    end

  end
end
