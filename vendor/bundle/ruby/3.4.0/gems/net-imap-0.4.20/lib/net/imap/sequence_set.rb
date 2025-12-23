# frozen_string_literal: true

module Net
  class IMAP

    ##
    # An \IMAP sequence set is a set of message sequence numbers or unique
    # identifier numbers ("UIDs").  It contains numbers and ranges of numbers.
    # The numbers are all non-zero unsigned 32-bit integers and one special
    # value (<tt>"*"</tt>) that represents the largest value in the mailbox.
    #
    # Certain types of \IMAP responses will contain a SequenceSet, for example
    # the data for a <tt>"MODIFIED"</tt> ResponseCode.  Some \IMAP commands may
    # receive a SequenceSet as an argument, for example IMAP#search, IMAP#fetch,
    # and IMAP#store.
    #
    # == EXPERIMENTAL API
    #
    # SequenceSet is currently experimental.  Only two methods, ::[] and
    # #valid_string, are considered stable.  Although the API isn't expected to
    # change much, any other methods may be removed or changed without
    # deprecation.
    #
    # == Creating sequence sets
    #
    # SequenceSet.new with no arguments creates an empty sequence set.  Note
    # that an empty sequence set is invalid in the \IMAP grammar.
    #
    #     set = Net::IMAP::SequenceSet.new
    #     set.empty?        #=> true
    #     set.valid?        #=> false
    #     set.valid_string  #!> raises DataFormatError
    #     set << 1..10
    #     set.empty?        #=> false
    #     set.valid?        #=> true
    #     set.valid_string  #=> "1:10"
    #
    # SequenceSet.new may receive a single optional argument: a non-zero 32 bit
    # unsigned integer, a range, a <tt>sequence-set</tt> formatted string,
    # another sequence set, or an enumerable containing any of these.
    #
    #     set = Net::IMAP::SequenceSet.new(1)
    #     set.valid_string  #=> "1"
    #     set = Net::IMAP::SequenceSet.new(1..100)
    #     set.valid_string  #=> "1:100"
    #     set = Net::IMAP::SequenceSet.new(1...100)
    #     set.valid_string  #=> "1:99"
    #     set = Net::IMAP::SequenceSet.new([1, 2, 5..])
    #     set.valid_string  #=> "1:2,5:*"
    #     set = Net::IMAP::SequenceSet.new("1,2,3:7,5,6:10,2048,1024")
    #     set.valid_string  #=> "1,2,3:7,5,6:10,2048,1024"
    #     set = Net::IMAP::SequenceSet.new(1, 2, 3..7, 5, 6..10, 2048, 1024)
    #     set.valid_string  #=> "1:10,55,1024:2048"
    #
    # Use ::[] with one or more arguments to create a frozen SequenceSet.  An
    # invalid (empty) set cannot be created with ::[].
    #
    #     set = Net::IMAP::SequenceSet["1,2,3:7,5,6:10,2048,1024"]
    #     set.valid_string  #=> "1,2,3:7,5,6:10,2048,1024"
    #     set = Net::IMAP::SequenceSet[1, 2, [3..7, 5], 6..10, 2048, 1024]
    #     set.valid_string  #=> "1:10,55,1024:2048"
    #
    # == Ordered and Normalized sets
    #
    # Sometimes the order of the set's members is significant, such as with the
    # +ESORT+, <tt>CONTEXT=SORT</tt>, and +UIDPLUS+ extensions.  So, when a
    # sequence set is created by the parser or with a single string value, that
    # #string representation is preserved.
    #
    # Internally, SequenceSet stores a normalized representation which sorts all
    # entries, de-duplicates numbers, and coalesces adjacent or overlapping
    # ranges.  Most methods use this normalized representation to achieve
    # <tt>O(lg n)</tt> porformance.  Use #entries or #each_entry to enumerate
    # the set in its original order.
    #
    # Most modification methods convert #string to its normalized form.  To
    # preserve #string order while modifying a set, use #append, #string=, or
    # #replace.
    #
    # == Using <tt>*</tt>
    #
    # \IMAP sequence sets may contain a special value <tt>"*"</tt>, which
    # represents the largest number in use.  From +seq-number+ in
    # {RFC9051 §9}[https://www.rfc-editor.org/rfc/rfc9051.html#section-9-5]:
    # >>>
    #   In the case of message sequence numbers, it is the number of messages
    #   in a non-empty mailbox.  In the case of unique identifiers, it is the
    #   unique identifier of the last message in the mailbox or, if the
    #   mailbox is empty, the mailbox's current UIDNEXT value.
    #
    # When creating a SequenceSet, <tt>*</tt> may be input as <tt>-1</tt>,
    # <tt>"*"</tt>, <tt>:*</tt>, an endless range, or a range ending in
    # <tt>-1</tt>.  When converting to #elements, #ranges, or #numbers, it will
    # output as either <tt>:*</tt> or an endless range.  For example:
    #
    #   Net::IMAP::SequenceSet["1,3,*"].to_a      #=> [1, 3, :*]
    #   Net::IMAP::SequenceSet["1,234:*"].to_a    #=> [1, 234..]
    #   Net::IMAP::SequenceSet[1234..-1].to_a     #=> [1234..]
    #   Net::IMAP::SequenceSet[1234..].to_a       #=> [1234..]
    #
    #   Net::IMAP::SequenceSet[1234..].to_s       #=> "1234:*"
    #   Net::IMAP::SequenceSet[1234..-1].to_s     #=> "1234:*"
    #
    # Use #limit to convert <tt>"*"</tt> to a maximum value.  When a range
    # includes <tt>"*"</tt>, the maximum value will always be matched:
    #
    #   Net::IMAP::SequenceSet["9999:*"].limit(max: 25)
    #   #=> Net::IMAP::SequenceSet["25"]
    #
    # === Surprising <tt>*</tt> behavior
    #
    # When a set includes <tt>*</tt>, some methods may have surprising behavior.
    #
    # For example, #complement treats <tt>*</tt> as its own number.  This way,
    # the #intersection of a set and its #complement will always be empty.
    # This is not how an \IMAP server interprets the set: it will convert
    # <tt>*</tt> to either the number of messages in the mailbox or +UIDNEXT+,
    # as appropriate.  And there _will_ be overlap between a set and its
    # complement after #limit is applied to each:
    #
    #   ~Net::IMAP::SequenceSet["*"]  == Net::IMAP::SequenceSet[1..(2**32-1)]
    #   ~Net::IMAP::SequenceSet[1..5] == Net::IMAP::SequenceSet["6:*"]
    #
    #   set = Net::IMAP::SequenceSet[1..5]
    #   (set & ~set).empty? => true
    #
    #   (set.limit(max: 4) & (~set).limit(max: 4)).to_a => [4]
    #
    # When counting the number of numbers in a set, <tt>*</tt> will be counted
    # _except_ when UINT32_MAX is also in the set:
    #   UINT32_MAX = 2**32 - 1
    #   Net::IMAP::SequenceSet["*"].count                   => 1
    #   Net::IMAP::SequenceSet[1..UINT32_MAX - 1, :*].count => UINT32_MAX
    #
    #   Net::IMAP::SequenceSet["1:*"].count                 => UINT32_MAX
    #   Net::IMAP::SequenceSet[UINT32_MAX, :*].count        => 1
    #   Net::IMAP::SequenceSet[UINT32_MAX..].count          => 1
    #
    # == What's here?
    #
    # SequenceSet provides methods for:
    # * {Creating a SequenceSet}[rdoc-ref:SequenceSet@Methods+for+Creating+a+SequenceSet]
    # * {Comparing}[rdoc-ref:SequenceSet@Methods+for+Comparing]
    # * {Querying}[rdoc-ref:SequenceSet@Methods+for+Querying]
    # * {Iterating}[rdoc-ref:SequenceSet@Methods+for+Iterating]
    # * {Set Operations}[rdoc-ref:SequenceSet@Methods+for+Set+Operations]
    # * {Assigning}[rdoc-ref:SequenceSet@Methods+for+Assigning]
    # * {Deleting}[rdoc-ref:SequenceSet@Methods+for+Deleting]
    # * {IMAP String Formatting}[rdoc-ref:SequenceSet@Methods+for+IMAP+String+Formatting]
    #
    # === Methods for Creating a \SequenceSet
    # * ::[]: Creates a validated frozen sequence set from one or more inputs.
    # * ::new: Creates a new mutable sequence set, which may be empty (invalid).
    # * ::try_convert: Calls +to_sequence_set+ on an object and verifies that
    #   the result is a SequenceSet.
    # * ::empty: Returns a frozen empty (invalid) SequenceSet.
    # * ::full: Returns a frozen SequenceSet containing every possible number.
    #
    # === Methods for Comparing
    #
    # <i>Comparison to another \SequenceSet:</i>
    # - #==: Returns whether a given set contains the same numbers as +self+.
    # - #eql?: Returns whether a given set uses the same #string as +self+.
    #
    # <i>Comparison to objects which are convertible to \SequenceSet:</i>
    # - #===:
    #   Returns whether a given object is fully contained within +self+, or
    #   +nil+ if the object cannot be converted to a compatible type.
    # - #cover?:
    #   Returns whether a given object is fully contained within +self+.
    # - #intersect? (aliased as #overlap?):
    #   Returns whether +self+ and a given object have any common elements.
    # - #disjoint?:
    #   Returns whether +self+ and a given object have no common elements.
    #
    # === Methods for Querying
    # These methods do not modify +self+.
    #
    # <i>Set membership:</i>
    # - #include? (aliased as #member?):
    #   Returns whether a given element (nz-number, range, or <tt>*</tt>) is
    #   contained by the set.
    # - #include_star?: Returns whether the set contains <tt>*</tt>.
    #
    # <i>Minimum and maximum value elements:</i>
    # - #min: Returns the minimum number in the set.
    # - #max: Returns the maximum number in the set.
    # - #minmax: Returns the minimum and maximum numbers in the set.
    #
    # <i>Accessing value by offset in sorted set:</i>
    # - #[] (aliased as #slice): Returns the number or consecutive subset at a
    #   given offset or range of offsets in the sorted set.
    # - #at: Returns the number at a given offset in the sorted set.
    # - #find_index: Returns the given number's offset in the sorted set.
    #
    # <i>Accessing value by offset in ordered entries</i>
    # - #ordered_at: Returns the number at a given offset in the ordered entries.
    # - #find_ordered_index: Returns the index of the given number's first
    #   occurrence in entries.
    #
    # <i>Set cardinality:</i>
    # - #count (aliased as #size): Returns the count of numbers in the set.
    #   Duplicated numbers are not counted.
    # - #empty?: Returns whether the set has no members.  \IMAP syntax does not
    #   allow empty sequence sets.
    # - #valid?: Returns whether the set has any members.
    # - #full?: Returns whether the set contains every possible value, including
    #   <tt>*</tt>.
    #
    # <i>Denormalized properties:</i>
    # - #has_duplicates?: Returns whether the ordered entries repeat any
    #   numbers.
    # - #count_duplicates: Returns the count of repeated numbers in the ordered
    #   entries.
    # - #count_with_duplicates: Returns the count of numbers in the ordered
    #   entries, including any repeated numbers.
    #
    # === Methods for Iterating
    #
    # <i>Normalized (sorted and coalesced):</i>
    # - #each_element: Yields each number and range in the set, sorted and
    #   coalesced, and returns +self+.
    # - #elements (aliased as #to_a): Returns an Array of every number and range
    #   in the set, sorted and coalesced.
    # - #each_range:
    #   Yields each element in the set as a Range and returns +self+.
    # - #ranges: Returns an Array of every element in the set, converting
    #   numbers into ranges of a single value.
    # - #each_number: Yields each number in the set and returns +self+.
    # - #numbers: Returns an Array with every number in the set, expanding
    #   ranges into all of their contained numbers.
    # - #to_set: Returns a Set containing all of the #numbers in the set.
    #
    # <i>Order preserving:</i>
    # - #each_entry: Yields each number and range in the set, unsorted and
    #   without deduplicating numbers or coalescing ranges, and returns +self+.
    # - #entries: Returns an Array of every number and range in the set,
    #   unsorted and without deduplicating numbers or coalescing ranges.
    # - #each_ordered_number: Yields each number in the ordered entries and
    #   returns +self+.
    #
    # === Methods for \Set Operations
    # These methods do not modify +self+.
    #
    # - #| (aliased as #union and #+): Returns a new set combining all members
    #   from +self+ with all members from the other set.
    # - #& (aliased as #intersection): Returns a new set containing all members
    #   common to +self+ and the other set.
    # - #- (aliased as #difference): Returns a copy of +self+ with all members
    #   in the other set removed.
    # - #^ (aliased as #xor): Returns a new set containing all members from
    #   +self+ and the other set except those common to both.
    # - #~ (aliased as #complement): Returns a new set containing all members
    #   that are not in +self+
    # - #limit: Returns a copy of +self+ which has replaced <tt>*</tt> with a
    #   given maximum value and removed all members over that maximum.
    #
    # === Methods for Assigning
    # These methods add or replace elements in +self+.
    #
    # <i>Normalized (sorted and coalesced):</i>
    #
    # These methods always update #string to be fully sorted and coalesced.
    #
    # - #add (aliased as #<<): Adds a given element to the set; returns +self+.
    # - #add?: If the given element is not fully included the set, adds it and
    #   returns +self+; otherwise, returns +nil+.
    # - #merge: Adds all members of the given sets into this set; returns +self+.
    # - #complement!: Replaces the contents of the set with its own #complement.
    #
    # <i>Order preserving:</i>
    #
    # These methods _may_ cause #string to not be sorted or coalesced.
    #
    # - #append: Adds the given entry to the set, appending it to the existing
    #   string, and returns +self+.
    # - #string=: Assigns a new #string value and replaces #elements to match.
    # - #replace: Replaces the contents of the set with the contents
    #   of a given object.
    #
    # === Methods for Deleting
    # These methods remove elements from +self+, and update #string to be fully
    # sorted and coalesced.
    #
    # - #clear: Removes all elements in the set; returns +self+.
    # - #delete: Removes a given element from the set; returns +self+.
    # - #delete?: If the given element is included in the set, removes it and
    #   returns it; otherwise, returns +nil+.
    # - #delete_at: Removes the number at a given offset.
    # - #slice!: Removes the number or consecutive numbers at a given offset or
    #   range of offsets.
    # - #subtract: Removes all members of the given sets from this set; returns
    #   +self+.
    # - #limit!: Replaces <tt>*</tt> with a given maximum value and removes all
    #   members over that maximum; returns +self+.
    #
    # === Methods for \IMAP String Formatting
    #
    # - #to_s: Returns the +sequence-set+ string, or an empty string when the
    #   set is empty.
    # - #string: Returns the +sequence-set+ string, or nil when empty.
    # - #valid_string: Returns the +sequence-set+ string, or raises
    #   DataFormatError when the set is empty.
    # - #normalized_string: Returns a <tt>sequence-set</tt> string with its
    #   elements sorted and coalesced, or nil when the set is empty.
    # - #normalize: Returns a new set with this set's normalized +sequence-set+
    #   representation.
    # - #normalize!: Updates #string to its normalized +sequence-set+
    #   representation and returns +self+.
    #
    class SequenceSet
      # The largest possible non-zero unsigned 32-bit integer
      UINT32_MAX = 2**32 - 1

      # represents "*" internally, to simplify sorting (etc)
      STAR_INT  = UINT32_MAX + 1
      private_constant :STAR_INT

      # valid inputs for "*"
      STARS     = [:*, ?*, -1].freeze
      private_constant :STAR_INT, :STARS

      COERCIBLE = ->{ _1.respond_to? :to_sequence_set }
      ENUMABLE  = ->{ _1.respond_to?(:each) && _1.respond_to?(:empty?) }
      private_constant :COERCIBLE, :ENUMABLE

      class << self

        # :call-seq:
        #   SequenceSet[*inputs] -> valid frozen sequence set
        #
        # Returns a frozen SequenceSet, constructed from +inputs+.
        #
        # When only a single valid frozen SequenceSet is given, that same set is
        # returned.
        #
        # An empty SequenceSet is invalid and will raise a DataFormatError.
        #
        # Use ::new to create a mutable or empty SequenceSet.
        def [](first, *rest)
          if rest.empty?
            if first.is_a?(SequenceSet) && first.frozen? && first.valid?
              first
            else
              new(first).validate.freeze
            end
          else
            new(first).merge(*rest).validate.freeze
          end
        end

        # :call-seq:
        #   SequenceSet.try_convert(obj) -> sequence set or nil
        #
        # If +obj+ is a SequenceSet, returns +obj+.  If +obj+ responds_to
        # +to_sequence_set+, calls +obj.to_sequence_set+ and returns the result.
        # Otherwise returns +nil+.
        #
        # If +obj.to_sequence_set+ doesn't return a SequenceSet, an exception is
        # raised.
        def try_convert(obj)
          return obj if obj.is_a?(SequenceSet)
          return nil unless obj.respond_to?(:to_sequence_set)
          obj = obj.to_sequence_set
          return obj if obj.is_a?(SequenceSet)
          raise DataFormatError, "invalid object returned from to_sequence_set"
        end

        # Returns a frozen empty set singleton.  Note that valid \IMAP sequence
        # sets cannot be empty, so this set is _invalid_.
        def empty; EMPTY end

        # Returns a frozen full set singleton: <tt>"1:*"</tt>
        def full;  FULL end

      end

      # Create a new SequenceSet object from +input+, which may be another
      # SequenceSet, an IMAP formatted +sequence-set+ string, a number, a
      # range, <tt>:*</tt>, or an enumerable of these.
      #
      # Use ::[] to create a frozen (non-empty) SequenceSet.
      def initialize(input = nil) input ? replace(input) : clear end

      # Removes all elements and returns self.
      def clear; @tuples, @string = [], nil; self end

      # Replace the contents of the set with the contents of +other+ and returns
      # +self+.
      #
      # +other+ may be another SequenceSet, or it may be an IMAP +sequence-set+
      # string, a number, a range, <tt>*</tt>, or an enumerable of these.
      def replace(other)
        case other
        when SequenceSet then initialize_dup(other)
        when String      then self.string = other
        else                  clear; merge other
        end
        self
      end

      # Returns the \IMAP +sequence-set+ string representation, or raises a
      # DataFormatError when the set is empty.
      #
      # Use #string to return +nil+ or #to_s to return an empty string without
      # error.
      #
      # Related: #string, #normalized_string, #to_s
      def valid_string
        raise DataFormatError, "empty sequence-set" if empty?
        string
      end

      # Returns the \IMAP +sequence-set+ string representation, or +nil+ when
      # the set is empty.  Note that an empty set is invalid in the \IMAP
      # syntax.
      #
      # Use #valid_string to raise an exception when the set is empty, or #to_s
      # to return an empty string.
      #
      # If the set was created from a single string, it is not normalized.  If
      # the set is updated the string will be normalized.
      #
      # Related: #valid_string, #normalized_string, #to_s
      def string; @string ||= normalized_string if valid? end

      # Assigns a new string to #string and resets #elements to match.  It
      # cannot be set to an empty string—assign +nil+ or use #clear instead.
      # The string is validated but not normalized.
      #
      # Use #add or #merge to add a string to an existing set.
      #
      # Related: #replace, #clear
      def string=(str)
        if str.nil?
          clear
        else
          str = String.try_convert(str) or raise ArgumentError, "not a string"
          tuples = str_to_tuples str
          @tuples, @string = [], -str
          tuples_add tuples
        end
      end

      # Returns the \IMAP +sequence-set+ string representation, or an empty
      # string when the set is empty.  Note that an empty set is invalid in the
      # \IMAP syntax.
      #
      # Related: #valid_string, #normalized_string, #to_s
      def to_s; string || "" end

      # Freezes and returns the set.  A frozen SequenceSet is Ractor-safe.
      def freeze
        return self if frozen?
        string
        @tuples.each(&:freeze).freeze
        super
      end

      # :call-seq: self == other -> true or false
      #
      # Returns true when the other SequenceSet represents the same message
      # identifiers.  Encoding difference—such as order, overlaps, or
      # duplicates—are ignored.
      #
      #   Net::IMAP::SequenceSet["1:3"]   == Net::IMAP::SequenceSet["1:3"]
      #   #=> true
      #   Net::IMAP::SequenceSet["1,2,3"] == Net::IMAP::SequenceSet["1:3"]
      #   #=> true
      #   Net::IMAP::SequenceSet["1,3"]   == Net::IMAP::SequenceSet["3,1"]
      #   #=> true
      #   Net::IMAP::SequenceSet["9,1:*"] == Net::IMAP::SequenceSet["1:*"]
      #   #=> true
      #
      # Related: #eql?, #normalize
      def ==(other)
        self.class == other.class &&
          (to_s == other.to_s || tuples == other.tuples)
      end

      # :call-seq: eql?(other) -> true or false
      #
      # Hash equality requires the same encoded #string representation.
      #
      #   Net::IMAP::SequenceSet["1:3"]  .eql? Net::IMAP::SequenceSet["1:3"]
      #   #=> true
      #   Net::IMAP::SequenceSet["1,2,3"].eql? Net::IMAP::SequenceSet["1:3"]
      #   #=> false
      #   Net::IMAP::SequenceSet["1,3"]  .eql? Net::IMAP::SequenceSet["3,1"]
      #   #=> false
      #   Net::IMAP::SequenceSet["9,1:*"].eql? Net::IMAP::SequenceSet["1:*"]
      #   #=> false
      #
      # Related: #==, #normalize
      def eql?(other) self.class == other.class && string == other.string end

      # See #eql?
      def hash; [self.class, string].hash end

      # :call-seq: self === other -> true | false | nil
      #
      # Returns whether +other+ is contained within the set.  Returns +nil+ if a
      # StandardError is raised while converting +other+ to a comparable type.
      #
      # Related: #cover?, #include?, #include_star?
      def ===(other)
        cover?(other)
      rescue
        nil
      end

      # :call-seq: cover?(other) -> true | false | nil
      #
      # Returns whether +other+ is contained within the set.  +other+ may be any
      # object that would be accepted by ::new.
      #
      # Related: #===, #include?, #include_star?
      def cover?(other) input_to_tuples(other).none? { !include_tuple?(_1) } end

      # Returns +true+ when a given number or range is in +self+, and +false+
      # otherwise.  Returns +false+ unless +number+ is an Integer, Range, or
      # <tt>*</tt>.
      #
      #     set = Net::IMAP::SequenceSet["5:10,100,111:115"]
      #     set.include? 1      #=> false
      #     set.include? 5..10  #=> true
      #     set.include? 11..20 #=> false
      #     set.include? 100    #=> true
      #     set.include? 6      #=> true, covered by "5:10"
      #     set.include? 4..9   #=> true, covered by "5:10"
      #     set.include? "4:9"  #=> true, strings are parsed
      #     set.include? 4..9   #=> false, intersection is not sufficient
      #     set.include? "*"    #=> false, use #limit to re-interpret "*"
      #     set.include? -1     #=> false, -1 is interpreted as "*"
      #
      #     set = Net::IMAP::SequenceSet["5:10,100,111:*"]
      #     set.include? :*     #=> true
      #     set.include? "*"    #=> true
      #     set.include? -1     #=> true
      #     set.include? 200..  #=> true
      #     set.include? 100..  #=> false
      #
      # Related: #include_star?, #cover?, #===
      def include?(element) include_tuple? input_to_tuple element end

      alias member? include?

      # Returns +true+ when the set contains <tt>*</tt>.
      def include_star?; @tuples.last&.last == STAR_INT end

      # Returns +true+ if the set and a given object have any common elements,
      # +false+ otherwise.
      #
      #     Net::IMAP::SequenceSet["5:10"].intersect? "7,9,11" #=> true
      #     Net::IMAP::SequenceSet["5:10"].intersect? "11:33"  #=> false
      #
      # Related: #intersection, #disjoint?
      def intersect?(other)
        valid? && input_to_tuples(other).any? { intersect_tuple? _1 }
      end
      alias overlap? intersect?

      # Returns +true+ if the set and a given object have no common elements,
      # +false+ otherwise.
      #
      #     Net::IMAP::SequenceSet["5:10"].disjoint? "7,9,11" #=> false
      #     Net::IMAP::SequenceSet["5:10"].disjoint? "11:33"  #=> true
      #
      # Related: #intersection, #intersect?
      def disjoint?(other)
        empty? || input_to_tuples(other).none? { intersect_tuple? _1 }
      end

      # :call-seq: max(star: :*) => integer or star or nil
      #
      # Returns the maximum value in +self+, +star+ when the set includes
      # <tt>*</tt>, or +nil+ when the set is empty.
      def max(star: :*)
        (val = @tuples.last&.last) && val == STAR_INT ? star : val
      end

      # :call-seq: min(star: :*) => integer or star or nil
      #
      # Returns the minimum value in +self+, +star+ when the only value in the
      # set is <tt>*</tt>, or +nil+ when the set is empty.
      def min(star: :*)
        (val = @tuples.first&.first) && val == STAR_INT ? star : val
      end

      # :call-seq: minmax(star: :*) => nil or [integer, integer or star]
      #
      # Returns a 2-element array containing the minimum and maximum numbers in
      # +self+, or +nil+ when the set is empty.
      def minmax(star: :*); [min(star: star), max(star: star)] unless empty? end

      # Returns false when the set is empty.
      def valid?; !empty? end

      # Returns true if the set contains no elements
      def empty?; @tuples.empty? end

      # Returns true if the set contains every possible element.
      def full?; @tuples == [[1, STAR_INT]] end

      # :call-seq:
      #   self + other -> sequence set
      #   self | other -> sequence set
      #   union(other) -> sequence set
      #
      # Returns a new sequence set that has every number in the +other+ object
      # added.
      #
      # +other+ may be any object that would be accepted by ::new: a non-zero 32
      # bit unsigned integer, range, <tt>sequence-set</tt> formatted string,
      # another sequence set, or an enumerable containing any of these.
      #
      #     Net::IMAP::SequenceSet["1:5"] | 2 | [4..6, 99]
      #     #=> Net::IMAP::SequenceSet["1:6,99"]
      #
      # Related: #add, #merge
      def |(other) remain_frozen dup.merge other end
      alias :+    :|
      alias union :|

      # :call-seq:
      #   self - other      -> sequence set
      #   difference(other) -> sequence set
      #
      # Returns a new sequence set built by duplicating this set and removing
      # every number that appears in +other+.
      #
      # +other+ may be any object that would be accepted by ::new: a non-zero 32
      # bit unsigned integer, range, <tt>sequence-set</tt> formatted string,
      # another sequence set, or an enumerable containing any of these.
      #
      #     Net::IMAP::SequenceSet[1..5] - 2 - 4 - 6
      #     #=> Net::IMAP::SequenceSet["1,3,5"]
      #
      # Related: #subtract
      def -(other) remain_frozen dup.subtract other end
      alias difference :-

      # :call-seq:
      #   self & other        -> sequence set
      #   intersection(other) -> sequence set
      #
      # Returns a new sequence set containing only the numbers common to this
      # set and +other+.
      #
      # +other+ may be any object that would be accepted by ::new: a non-zero 32
      # bit unsigned integer, range, <tt>sequence-set</tt> formatted string,
      # another sequence set, or an enumerable containing any of these.
      #
      #     Net::IMAP::SequenceSet[1..5] & [2, 4, 6]
      #     #=> Net::IMAP::SequenceSet["2,4"]
      #
      # <tt>(seqset & other)</tt> is equivalent to <tt>(seqset - ~other)</tt>.
      def &(other)
        remain_frozen dup.subtract SequenceSet.new(other).complement!
      end
      alias intersection :&

      # :call-seq:
      #   self ^ other -> sequence set
      #   xor(other)   -> sequence set
      #
      # Returns a new sequence set containing numbers that are exclusive between
      # this set and +other+.
      #
      # +other+ may be any object that would be accepted by ::new: a non-zero 32
      # bit unsigned integer, range, <tt>sequence-set</tt> formatted string,
      # another sequence set, or an enumerable containing any of these.
      #
      #     Net::IMAP::SequenceSet[1..5] ^ [2, 4, 6]
      #     #=> Net::IMAP::SequenceSet["1,3,5:6"]
      #
      # <tt>(seqset ^ other)</tt> is equivalent to <tt>((seqset | other) -
      # (seqset & other))</tt>.
      def ^(other) remain_frozen (self | other).subtract(self & other) end
      alias xor :^

      # :call-seq:
      #   ~ self     -> sequence set
      #   complement -> sequence set
      #
      # Returns the complement of self, a SequenceSet which contains all numbers
      # _except_ for those in this set.
      #
      #     ~Net::IMAP::SequenceSet.full  #=> Net::IMAP::SequenceSet.empty
      #     ~Net::IMAP::SequenceSet.empty #=> Net::IMAP::SequenceSet.full
      #     ~Net::IMAP::SequenceSet["1:5,100:222"]
      #     #=> Net::IMAP::SequenceSet["6:99,223:*"]
      #     ~Net::IMAP::SequenceSet["6:99,223:*"]
      #     #=> Net::IMAP::SequenceSet["1:5,100:222"]
      #
      # Related: #complement!
      def ~; remain_frozen dup.complement! end
      alias complement :~

      # :call-seq:
      #   add(element)   -> self
      #   self << other -> self
      #
      # Adds a range or number to the set and returns +self+.
      #
      # #string will be regenerated.  Use #merge to add many elements at once.
      #
      # Related: #add?, #merge, #union
      def add(element)
        tuple_add input_to_tuple element
        normalize!
      end
      alias << add

      # Adds a range or number to the set and returns +self+.
      #
      # Unlike #add, #merge, or #union, the new value is appended to #string.
      # This may result in a #string which has duplicates or is out-of-order.
      def append(entry)
        modifying!
        tuple = input_to_tuple entry
        entry = tuple_to_str tuple
        string unless empty? # write @string before tuple_add
        tuple_add tuple
        @string = -(@string ? "#{@string},#{entry}" : entry)
        self
      end

      # :call-seq: add?(element) -> self or nil
      #
      # Adds a range or number to the set and returns +self+.  Returns +nil+
      # when the element is already included in the set.
      #
      # #string will be regenerated.  Use #merge to add many elements at once.
      #
      # Related: #add, #merge, #union, #include?
      def add?(element)
        add element unless include? element
      end

      # :call-seq: delete(element) -> self
      #
      # Deletes the given range or number from the set and returns +self+.
      #
      # #string will be regenerated after deletion.  Use #subtract to remove
      # many elements at once.
      #
      # Related: #delete?, #delete_at, #subtract, #difference
      def delete(element)
        tuple_subtract input_to_tuple element
        normalize!
      end

      # :call-seq:
      #   delete?(number) -> integer or nil
      #   delete?(star)   -> :* or nil
      #   delete?(range)  -> sequence set or nil
      #
      # Removes a specified value from the set, and returns the removed value.
      # Returns +nil+ if nothing was removed.
      #
      # Returns an integer when the specified +number+ argument was removed:
      #     set = Net::IMAP::SequenceSet.new [5..10, 20]
      #     set.delete?(7)      #=> 7
      #     set                 #=> #<Net::IMAP::SequenceSet "5:6,8:10,20">
      #     set.delete?("20")   #=> 20
      #     set                 #=> #<Net::IMAP::SequenceSet "5:6,8:10">
      #     set.delete?(30)     #=> nil
      #
      # Returns <tt>:*</tt> when <tt>*</tt> or <tt>-1</tt> is specified and
      # removed:
      #     set = Net::IMAP::SequenceSet.new "5:9,20,35,*"
      #     set.delete?(-1)  #=> :*
      #     set              #=> #<Net::IMAP::SequenceSet "5:9,20,35">
      #
      # And returns a new SequenceSet when a range is specified:
      #
      #     set = Net::IMAP::SequenceSet.new [5..10, 20]
      #     set.delete?(9..)  #=> #<Net::IMAP::SequenceSet "9:10,20">
      #     set               #=> #<Net::IMAP::SequenceSet "5:8">
      #     set.delete?(21..) #=> nil
      #
      # #string will be regenerated after deletion.
      #
      # Related: #delete, #delete_at, #subtract, #difference, #disjoint?
      def delete?(element)
        tuple = input_to_tuple element
        if tuple.first == tuple.last
          return unless include_tuple? tuple
          tuple_subtract tuple
          normalize!
          from_tuple_int tuple.first
        else
          copy = dup
          tuple_subtract tuple
          normalize!
          copy if copy.subtract(self).valid?
        end
      end

      # :call-seq: delete_at(index) -> number or :* or nil
      #
      # Deletes a number the set, indicated by the given +index+.  Returns the
      # number that was removed, or +nil+ if nothing was removed.
      #
      # #string will be regenerated after deletion.
      #
      # Related: #delete, #delete?, #slice!, #subtract, #difference
      def delete_at(index)
        slice! Integer(index.to_int)
      end

      # :call-seq:
      #    slice!(index)          -> integer or :* or nil
      #    slice!(start, length)  -> sequence set or nil
      #    slice!(range)          -> sequence set or nil
      #
      # Deletes a number or consecutive numbers from the set, indicated by the
      # given +index+, +start+ and +length+, or +range+ of offsets.  Returns the
      # number or sequence set that was removed, or +nil+ if nothing was
      # removed.  Arguments are interpreted the same as for #slice or #[].
      #
      # #string will be regenerated after deletion.
      #
      # Related: #slice, #delete_at, #delete, #delete?, #subtract, #difference
      def slice!(index, length = nil)
        deleted = slice(index, length) and subtract deleted
        deleted
      end

      # Merges all of the elements that appear in any of the +sets+ into the
      # set, and returns +self+.
      #
      # The +sets+ may be any objects that would be accepted by ::new: non-zero
      # 32 bit unsigned integers, ranges, <tt>sequence-set</tt> formatted
      # strings, other sequence sets, or enumerables containing any of these.
      #
      # #string will be regenerated after all sets have been merged.
      #
      # Related: #add, #add?, #union
      def merge(*sets)
        tuples_add input_to_tuples sets
        normalize!
      end

      # Removes all of the elements that appear in any of the given +sets+ from
      # the set, and returns +self+.
      #
      # The +sets+ may be any objects that would be accepted by ::new: non-zero
      # 32 bit unsigned integers, ranges, <tt>sequence-set</tt> formatted
      # strings, other sequence sets, or enumerables containing any of these.
      #
      # Related: #difference
      def subtract(*sets)
        tuples_subtract input_to_tuples sets
        normalize!
      end

      # Returns an array of ranges and integers and <tt>:*</tt>.
      #
      # The entries are in the same order they appear in #string, with no
      # sorting, deduplication, or coalescing.  When #string is in its
      # normalized form, this will return the same result as #elements.
      # This is useful when the given order is significant, for example in a
      # ESEARCH response to IMAP#sort.
      #
      # Related: #each_entry, #elements
      def entries; each_entry.to_a end

      # Returns an array of ranges and integers and <tt>:*</tt>.
      #
      # The returned elements are sorted and coalesced, even when the input
      # #string is not.  <tt>*</tt> will sort last.  See #normalize.
      #
      # By itself, <tt>*</tt> translates to <tt>:*</tt>.  A range containing
      # <tt>*</tt> translates to an endless range.  Use #limit to translate both
      # cases to a maximum value.
      #
      # The returned elements will be sorted and coalesced, even when the input
      # #string is not.  <tt>*</tt> will sort last.  See #normalize.
      #
      #   Net::IMAP::SequenceSet["2,5:9,6,*,12:11"].elements
      #   #=> [2, 5..9, 11..12, :*]
      #
      # Related: #each_element, #ranges, #numbers
      def elements; each_element.to_a end
      alias to_a elements

      # Returns an array of ranges
      #
      # The returned elements are sorted and coalesced, even when the input
      # #string is not.  <tt>*</tt> will sort last.  See #normalize.
      #
      # <tt>*</tt> translates to an endless range.  By itself, <tt>*</tt>
      # translates to <tt>:*..</tt>.  Use #limit to set <tt>*</tt> to a maximum
      # value.
      #
      # The returned ranges will be sorted and coalesced, even when the input
      # #string is not.  <tt>*</tt> will sort last.  See #normalize.
      #
      #   Net::IMAP::SequenceSet["2,5:9,6,*,12:11"].ranges
      #   #=> [2..2, 5..9, 11..12, :*..]
      #   Net::IMAP::SequenceSet["123,999:*,456:789"].ranges
      #   #=> [123..123, 456..789, 999..]
      #
      # Related: #each_range, #elements, #numbers, #to_set
      def ranges; each_range.to_a end

      # Returns a sorted array of all of the number values in the sequence set.
      #
      # The returned numbers are sorted and de-duplicated, even when the input
      # #string is not.  See #normalize.
      #
      #   Net::IMAP::SequenceSet["2,5:9,6,12:11"].numbers
      #   #=> [2, 5, 6, 7, 8, 9, 11, 12]
      #
      # If the set contains a <tt>*</tt>, RangeError is raised.  See #limit.
      #
      #   Net::IMAP::SequenceSet["10000:*"].numbers
      #   #!> RangeError
      #
      # *WARNING:* Even excluding sets with <tt>*</tt>, an enormous result can
      # easily be created.  An array with over 4 billion integers could be
      # returned, requiring up to 32GiB of memory on a 64-bit architecture.
      #
      #   Net::IMAP::SequenceSet[10000..2**32-1].numbers
      #   # ...probably freezes the process for a while...
      #   #!> NoMemoryError (probably)
      #
      # For safety, consider using #limit or #intersection to set an upper
      # bound.  Alternatively, use #each_element, #each_range, or even
      # #each_number to avoid allocation of a result array.
      #
      # Related: #elements, #ranges, #to_set
      def numbers; each_number.to_a end

      # Yields each number or range in #string to the block and returns +self+.
      # Returns an enumerator when called without a block.
      #
      # The entries are yielded in the same order they appear in #string, with
      # no sorting, deduplication, or coalescing.  When #string is in its
      # normalized form, this will yield the same values as #each_element.
      #
      # Related: #entries, #each_element
      def each_entry(&block) # :yields: integer or range or :*
        return to_enum(__method__) unless block_given?
        each_entry_tuple do yield tuple_to_entry _1 end
      end

      # Yields each number or range (or <tt>:*</tt>) in #elements to the block
      # and returns self.  Returns an enumerator when called without a block.
      #
      # The returned numbers are sorted and de-duplicated, even when the input
      # #string is not.  See #normalize.
      #
      # Related: #elements, #each_entry
      def each_element # :yields: integer or range or :*
        return to_enum(__method__) unless block_given?
        @tuples.each do yield tuple_to_entry _1 end
        self
      end

      private

      def each_entry_tuple(&block)
        return to_enum(__method__) unless block_given?
        if @string
          @string.split(",") do block.call str_to_tuple _1 end
        else
          @tuples.each(&block)
        end
        self
      end

      def tuple_to_entry((min, max))
        if    min == STAR_INT then :*
        elsif max == STAR_INT then min..
        elsif min == max      then min
        else                       min..max
        end
      end

      public

      # Yields each range in #ranges to the block and returns self.
      # Returns an enumerator when called without a block.
      #
      # Related: #ranges
      def each_range # :yields: range
        return to_enum(__method__) unless block_given?
        @tuples.each do |min, max|
          if    min == STAR_INT then yield :*..
          elsif max == STAR_INT then yield min..
          else                       yield min..max
          end
        end
        self
      end

      # Yields each number in #numbers to the block and returns self.
      # If the set contains a <tt>*</tt>, RangeError will be raised.
      #
      # Returns an enumerator when called without a block (even if the set
      # contains <tt>*</tt>).
      #
      # Related: #numbers, #each_ordered_number
      def each_number(&block) # :yields: integer
        return to_enum(__method__) unless block_given?
        raise RangeError, '%s contains "*"' % [self.class] if include_star?
        @tuples.each do each_number_in_tuple _1, _2, &block end
        self
      end

      # Yields each number in #entries to the block and returns self.
      # If the set contains a <tt>*</tt>, RangeError will be raised.
      #
      # Returns an enumerator when called without a block (even if the set
      # contains <tt>*</tt>).
      #
      # Related: #entries, #each_number
      def each_ordered_number(&block)
        return to_enum(__method__) unless block_given?
        raise RangeError, '%s contains "*"' % [self.class] if include_star?
        each_entry_tuple do each_number_in_tuple _1, _2, &block end
      end

      private def each_number_in_tuple(min, max, &block)
        if    min == STAR_INT then yield :*
        elsif min == max      then yield min
        elsif max != STAR_INT then (min..max).each(&block)
        else
          raise RangeError, "#{SequenceSet} cannot enumerate range with '*'"
        end
      end

      # Returns a Set with all of the #numbers in the sequence set.
      #
      # If the set contains a <tt>*</tt>, RangeError will be raised.
      #
      # See #numbers for the warning about very large sets.
      #
      # Related: #elements, #ranges, #numbers
      def to_set; Set.new(numbers) end

      # Returns the count of #numbers in the set.
      #
      # <tt>*</tt> will be counted as <tt>2**32 - 1</tt> (the maximum 32-bit
      # unsigned integer value).
      #
      # Related: #count_with_duplicates
      def count
        @tuples.sum(@tuples.count) { _2 - _1 } +
          (include_star? && include?(UINT32_MAX) ? -1 : 0)
      end

      alias size count

      # Returns the count of numbers in the ordered #entries, including any
      # repeated numbers.
      #
      # <tt>*</tt> will be counted as <tt>2**32 - 1</tt> (the maximum 32-bit
      # unsigned integer value).
      #
      # When #string is normalized, this behaves the same as #count.
      #
      # Related: #entries, #count_duplicates, #has_duplicates?
      def count_with_duplicates
        return count unless @string
        each_entry_tuple.sum {|min, max|
          max - min + ((max == STAR_INT && min != STAR_INT) ? 0 : 1)
        }
      end

      # Returns the count of repeated numbers in the ordered #entries, the
      # difference between #count_with_duplicates and #count.
      #
      # When #string is normalized, this is zero.
      #
      # Related: #entries, #count_with_duplicates, #has_duplicates?
      def count_duplicates
        return 0 unless @string
        count_with_duplicates - count
      end

      # :call-seq: has_duplicates? -> true | false
      #
      # Returns whether or not the ordered #entries repeat any numbers.
      #
      # Always returns +false+ when #string is normalized.
      #
      # Related: #entries, #count_with_duplicates, #count_duplicates?
      def has_duplicates?
        return false unless @string
        count_with_duplicates != count
      end

      # Returns the (sorted and deduplicated) index of +number+ in the set, or
      # +nil+ if +number+ isn't in the set.
      #
      # Related: #[], #at, #find_ordered_index
      def find_index(number)
        number = to_tuple_int number
        each_tuple_with_index(@tuples) do |min, max, idx_min|
          number <  min and return nil
          number <= max and return from_tuple_int(idx_min + (number - min))
        end
        nil
      end

      # Returns the first index of +number+ in the ordered #entries, or
      # +nil+ if +number+ isn't in the set.
      #
      # Related: #find_index
      def find_ordered_index(number)
        number = to_tuple_int number
        each_tuple_with_index(each_entry_tuple) do |min, max, idx_min|
          if min <= number && number <= max
            return from_tuple_int(idx_min + (number - min))
          end
        end
        nil
      end

      private

      def each_tuple_with_index(tuples)
        idx_min = 0
        tuples.each do |min, max|
          idx_max = idx_min + (max - min)
          yield min, max, idx_min, idx_max
          idx_min = idx_max + 1
        end
        idx_min
      end

      def reverse_each_tuple_with_index(tuples)
        idx_max = -1
        tuples.reverse_each do |min, max|
          yield min, max, (idx_min = idx_max - (max - min)), idx_max
          idx_max = idx_min - 1
        end
        idx_max
      end

      public

      # :call-seq: at(index) -> integer or nil
      #
      # Returns the number at the given +index+ in the sorted set, without
      # modifying the set.
      #
      # +index+ is interpreted the same as in #[], except that #at only allows a
      # single integer argument.
      #
      # Related: #[], #slice, #ordered_at
      def at(index)
        lookup_number_by_tuple_index(tuples, index)
      end

      # :call-seq: ordered_at(index) -> integer or nil
      #
      # Returns the number at the given +index+ in the ordered #entries, without
      # modifying the set.
      #
      # +index+ is interpreted the same as in #at (and #[]), except that
      # #ordered_at applies to the ordered #entries, not the sorted set.
      #
      # Related: #[], #slice, #ordered_at
      def ordered_at(index)
        lookup_number_by_tuple_index(each_entry_tuple, index)
      end

      private def lookup_number_by_tuple_index(tuples, index)
        index = Integer(index.to_int)
        if index.negative?
          reverse_each_tuple_with_index(tuples) do |min, max, idx_min, idx_max|
            idx_min <= index and return from_tuple_int(min + (index - idx_min))
          end
        else
          each_tuple_with_index(tuples) do |min, _, idx_min, idx_max|
            index <= idx_max and return from_tuple_int(min + (index - idx_min))
          end
        end
        nil
      end

      # :call-seq:
      #    seqset[index]         -> integer or :* or nil
      #    slice(index)          -> integer or :* or nil
      #    seqset[start, length] -> sequence set or nil
      #    slice(start, length)  -> sequence set or nil
      #    seqset[range]         -> sequence set or nil
      #    slice(range)          -> sequence set or nil
      #
      # Returns a number or a subset from the _sorted_ set, without modifying
      # the set.
      #
      # When an Integer argument +index+ is given, the number at offset +index+
      # in the sorted set is returned:
      #
      #     set = Net::IMAP::SequenceSet["10:15,20:23,26"]
      #     set[0]   #=> 10
      #     set[5]   #=> 15
      #     set[10]  #=> 26
      #
      # If +index+ is negative, it counts relative to the end of the sorted set:
      #     set = Net::IMAP::SequenceSet["10:15,20:23,26"]
      #     set[-1]  #=> 26
      #     set[-3]  #=> 22
      #     set[-6]  #=> 15
      #
      # If +index+ is out of range, +nil+ is returned.
      #
      #     set = Net::IMAP::SequenceSet["10:15,20:23,26"]
      #     set[11]  #=> nil
      #     set[-12] #=> nil
      #
      # The result is based on the sorted and de-duplicated set, not on the
      # ordered #entries in #string.
      #
      #     set = Net::IMAP::SequenceSet["12,20:23,11:16,21"]
      #     set[0]   #=> 11
      #     set[-1]  #=> 23
      #
      # Related: #at
      def [](index, length = nil)
        if    length              then slice_length(index, length)
        elsif index.is_a?(Range)  then slice_range(index)
        else                           at(index)
        end
      end

      alias slice :[]

      private

      def slice_length(start, length)
        start  = Integer(start.to_int)
        length = Integer(length.to_int)
        raise ArgumentError, "length must be positive" unless length.positive?
        last = start + length - 1 unless start.negative? && start.abs <= length
        slice_range(start..last)
      end

      def slice_range(range)
        first = range.begin ||  0
        last  = range.end   || -1
        last -= 1 if range.exclude_end? && range.end && last != STAR_INT
        if (first * last).positive? && last < first
          SequenceSet.empty
        elsif (min = at(first))
          max = at(last)
          if    max == :*  then self & (min..)
          elsif min <= max then self & (min..max)
          else                  SequenceSet.empty
          end
        end
      end

      public

      # Returns a frozen SequenceSet with <tt>*</tt> converted to +max+, numbers
      # and ranges over +max+ removed, and ranges containing +max+ converted to
      # end at +max+.
      #
      #   Net::IMAP::SequenceSet["5,10:22,50"].limit(max: 20).to_s
      #   #=> "5,10:20"
      #
      # <tt>*</tt> is always interpreted as the maximum value.  When the set
      # contains <tt>*</tt>, it will be set equal to the limit.
      #
      #   Net::IMAP::SequenceSet["*"].limit(max: 37)
      #   #=> Net::IMAP::SequenceSet["37"]
      #   Net::IMAP::SequenceSet["5:*"].limit(max: 37)
      #   #=> Net::IMAP::SequenceSet["5:37"]
      #   Net::IMAP::SequenceSet["500:*"].limit(max: 37)
      #   #=> Net::IMAP::SequenceSet["37"]
      #
      def limit(max:)
        max = to_tuple_int(max)
        if    empty?                      then self.class.empty
        elsif !include_star? && max < min then self.class.empty
        elsif max(star: STAR_INT) <= max  then frozen? ? self : dup.freeze
        else                                   dup.limit!(max: max).freeze
        end
      end

      # Removes all members over +max+ and returns self.  If <tt>*</tt> is a
      # member, it will be converted to +max+.
      #
      # Related: #limit
      def limit!(max:)
        star = include_star?
        max  = to_tuple_int(max)
        tuple_subtract [max + 1, STAR_INT]
        tuple_add      [max,     max     ] if star
        normalize!
      end

      # :call-seq: complement! -> self
      #
      # Converts the SequenceSet to its own #complement.  It will contain all
      # possible values _except_ for those currently in the set.
      #
      # Related: #complement
      def complement!
        return replace(self.class.full) if empty?
        return clear                    if full?
        flat = @tuples.flat_map { [_1 - 1, _2 + 1] }
        if flat.first < 1         then flat.shift else flat.unshift 1        end
        if STAR_INT   < flat.last then flat.pop   else flat.push    STAR_INT end
        @tuples = flat.each_slice(2).to_a
        normalize!
      end

      # Returns a new SequenceSet with a normalized string representation.
      #
      # The returned set's #string is sorted and deduplicated.  Adjacent or
      # overlapping elements will be merged into a single larger range.
      #
      #   Net::IMAP::SequenceSet["1:5,3:7,10:9,10:11"].normalize
      #   #=> Net::IMAP::SequenceSet["1:7,9:11"]
      #
      # Related: #normalize!, #normalized_string
      def normalize
        str = normalized_string
        return self if frozen? && str == string
        remain_frozen dup.instance_exec { @string = str&.-@; self }
      end

      # Resets #string to be sorted, deduplicated, and coalesced.  Returns
      # +self+.
      #
      # Related: #normalize, #normalized_string
      def normalize!
        @string = nil
        self
      end

      # Returns a normalized +sequence-set+ string representation, sorted
      # and deduplicated.  Adjacent or overlapping elements will be merged into
      # a single larger range.  Returns +nil+ when the set is empty.
      #
      #   Net::IMAP::SequenceSet["1:5,3:7,10:9,10:11"].normalized_string
      #   #=> "1:7,9:11"
      #
      # Related: #normalize!, #normalize
      def normalized_string
        @tuples.empty? ? nil : -@tuples.map { tuple_to_str _1 }.join(",")
      end

      def inspect
        if empty?
          (frozen? ?  "%s.empty" : "#<%s empty>") % [self.class]
        elsif frozen?
          "%s[%p]"   % [self.class, to_s]
        else
          "#<%s %p>" % [self.class, to_s]
        end
      end

      # Returns self
      alias to_sequence_set itself

      # Unstable API: currently for internal use only (Net::IMAP#validate_data)
      def validate # :nodoc:
        empty? and raise DataFormatError, "empty sequence-set is invalid"
        self
      end

      # Unstable API: for internal use only (Net::IMAP#send_data)
      def send_data(imap, tag) # :nodoc:
        imap.__send__(:put_string, valid_string)
      end

      protected

      attr_reader :tuples # :nodoc:

      private

      def remain_frozen(set) frozen? ? set.freeze : set end

      # frozen clones are shallow copied
      def initialize_clone(other)
        other.frozen? ? super : initialize_dup(other)
      end

      def initialize_dup(other)
        @tuples = other.tuples.map(&:dup)
        @string = other.string&.-@
        super
      end

      def input_to_tuple(entry)
        entry = input_try_convert entry
        case entry
        when *STARS, Integer then [int = to_tuple_int(entry), int]
        when Range           then range_to_tuple(entry)
        when String          then str_to_tuple(entry)
        else
          raise DataFormatError, "expected number or range, got %p" % [entry]
        end
      end

      def input_to_tuples(set)
        set = input_try_convert set
        case set
        when *STARS, Integer, Range then [input_to_tuple(set)]
        when String      then str_to_tuples set
        when SequenceSet then set.tuples
        when ENUMABLE    then set.flat_map { input_to_tuples _1 }
        when nil         then []
        else
          raise DataFormatError,
                "expected nz-number, range, string, or enumerable; " \
                "got %p" % [set]
        end
      end

      # unlike SequenceSet#try_convert, this returns an Integer, Range,
      # String, Set, Array, or... any type of object.
      def input_try_convert(input)
        SequenceSet.try_convert(input) ||
          # Integer.try_convert(input) || # ruby 3.1+
          input.respond_to?(:to_int) && Integer(input.to_int) ||
          String.try_convert(input) ||
          input
      end

      def range_to_tuple(range)
        first = to_tuple_int(range.begin || 1)
        last  = to_tuple_int(range.end   || :*)
        last -= 1 if range.exclude_end? && range.end && last != STAR_INT
        unless first <= last
          raise DataFormatError, "invalid range for sequence-set: %p" % [range]
        end
        [first, last]
      end

      def to_tuple_int(obj) STARS.include?(obj) ? STAR_INT : nz_number(obj) end
      def from_tuple_int(num) num == STAR_INT ? :* : num end

      def tuple_to_str(tuple) tuple.uniq.map{ from_tuple_int _1 }.join(":") end
      def str_to_tuples(str) str.split(",", -1).map! { str_to_tuple _1 } end
      def str_to_tuple(str)
        raise DataFormatError, "invalid sequence set string" if str.empty?
        str.split(":", 2).map! { to_tuple_int _1 }.minmax
      end

      def include_tuple?((min, max)) range_gte_to(min)&.cover?(min..max) end

      def intersect_tuple?((min, max))
        range = range_gte_to(min) and
          range.include?(min) || range.include?(max) || (min..max).cover?(range)
      end

      def modifying!
        if frozen?
          raise FrozenError, "can't modify frozen #{self.class}: %p" % [self]
        end
      end

      def tuples_add(tuples)      tuples.each do tuple_add _1      end; self end
      def tuples_subtract(tuples) tuples.each do tuple_subtract _1 end; self end

      #
      #   --|=====| |=====new tuple=====|                 append
      #   ?????????-|=====new tuple=====|-|===lower===|-- insert
      #
      #             |=====new tuple=====|
      #   ---------??=======lower=======??--------------- noop
      #
      #   ---------??===lower==|--|==|                    join remaining
      #   ---------??===lower==|--|==|----|===upper===|-- join until upper
      #   ---------??===lower==|--|==|--|=====upper===|-- join to upper
      def tuple_add(tuple)
        modifying!
        min, max = tuple
        lower, lower_idx = tuple_gte_with_index(min - 1)
        if    lower.nil?              then tuples << [min, max]
        elsif (max + 1) < lower.first then tuples.insert(lower_idx, [min, max])
        else  tuple_coalesce(lower, lower_idx, min, max)
        end
      end

      def tuple_coalesce(lower, lower_idx, min, max)
        return if lower.first <= min && max <= lower.last
        lower[0] = [min, lower.first].min
        lower[1] = [max, lower.last].max
        lower_idx += 1
        return if lower_idx == tuples.count
        tmax_adj = lower.last + 1
        upper, upper_idx = tuple_gte_with_index(tmax_adj)
        if upper
          tmax_adj < upper.first ? (upper_idx -= 1) : (lower[1] = upper.last)
        end
        tuples.slice!(lower_idx..upper_idx)
      end

      #         |====tuple================|
      # --|====|                               no more       1. noop
      # --|====|---------------------------|====lower====|-- 2. noop
      # -------|======lower================|---------------- 3. split
      # --------|=====lower================|---------------- 4. trim beginning
      #
      # -------|======lower====????????????----------------- trim lower
      # --------|=====lower====????????????----------------- delete lower
      #
      # -------??=====lower===============|----------------- 5. trim/delete one
      # -------??=====lower====|--|====|       no more       6. delete rest
      # -------??=====lower====|--|====|---|====upper====|-- 7. delete until
      # -------??=====lower====|--|====|--|=====upper====|-- 8. delete and trim
      def tuple_subtract(tuple)
        modifying!
        min, max = tuple
        lower, idx = tuple_gte_with_index(min)
        if    lower.nil?        then nil # case 1.
        elsif max < lower.first then nil # case 2.
        elsif max < lower.last  then tuple_trim_or_split   lower, idx, min, max
        else                         tuples_trim_or_delete lower, idx, min, max
        end
      end

      def tuple_trim_or_split(lower, idx, tmin, tmax)
        if lower.first < tmin # split
          tuples.insert(idx, [lower.first, tmin - 1])
        end
        lower[0] = tmax + 1
      end

      def tuples_trim_or_delete(lower, lower_idx, tmin, tmax)
        if lower.first < tmin # trim lower
          lower[1] = tmin - 1
          lower_idx += 1
        end
        if tmax == lower.last                           # case 5
          upper_idx = lower_idx
        elsif (upper, upper_idx = tuple_gte_with_index(tmax + 1))
          upper_idx -= 1                                # cases 7 and 8
          upper[0] = tmax + 1 if upper.first <= tmax    # case 8 (else case 7)
        end
        tuples.slice!(lower_idx..upper_idx)
      end

      def tuple_gte_with_index(num)
        idx = tuples.bsearch_index { _2 >= num } and [tuples[idx], idx]
      end

      def range_gte_to(num)
        first, last = tuples.bsearch { _2 >= num }
        first..last if first
      end

      def nz_number(num)
        case num
        when Integer, /\A[1-9]\d*\z/ then num = Integer(num)
        else raise DataFormatError, "%p is not a valid nz-number" % [num]
        end
        NumValidator.ensure_nz_number(num)
        num
      end

      # intentionally defined after the class implementation

      EMPTY = new.freeze
      FULL  = self["1:*"]
      private_constant :EMPTY, :FULL

    end
  end
end
