# frozen_string_literal: true

module Net
  class IMAP < Protocol

    # Net::IMAP::FetchData represents the contents of a FETCH response.
    # Net::IMAP#fetch and Net::IMAP#uid_fetch both return an array of
    # FetchData objects.
    #
    # === Fetch attributes
    #
    # See {[IMAP4rev1 §7.4.2]}[https://www.rfc-editor.org/rfc/rfc3501.html#section-7.4.2]
    # and {[IMAP4rev2 §7.5.2]}[https://www.rfc-editor.org/rfc/rfc9051.html#section-7.5.2]
    # for a full description of the standard fetch response data items, and
    # Net::IMAP@Message+envelope+and+body+structure for other relevant RFCs.
    #
    # ==== Static fetch data items
    #
    # Most message attributes are static, and must never change for a given
    # <tt>(server, account, mailbox, UIDVALIDITY, UID)</tt> tuple.
    #
    # The static fetch data items defined by both
    # IMAP4rev1[https://www.rfc-editor.org/rfc/rfc3501.html] and
    # IMAP4rev2[https://www.rfc-editor.org/rfc/rfc9051.html] are:
    #
    # * <b><tt>"UID"</tt></b> --- See #uid.
    # * <b><tt>"BODY"</tt></b> --- See #body.
    # * <b><tt>"BODY[#{section_spec}]"</tt></b>,
    #   <b><tt>"BODY[#{section_spec}]<#{offset}>"</tt></b> --- See #message,
    #   #part, #header, #header_fields, #header_fields_not, #mime, and #text.
    # * <b><tt>"BODYSTRUCTURE"</tt></b> --- See #bodystructure.
    # * <b><tt>"ENVELOPE"</tt></b> --- See #envelope.
    # * <b><tt>"INTERNALDATE"</tt></b> --- See #internaldate.
    # * <b><tt>"RFC822.SIZE"</tt></b> --- See #rfc822_size.
    #
    # IMAP4rev2[https://www.rfc-editor.org/rfc/rfc9051.html] adds the
    # additional fetch items from the +BINARY+ extension
    # {[RFC3516]}[https://www.rfc-editor.org/rfc/rfc3516.html]:
    #
    # * <b><tt>"BINARY[#{part}]"</tt></b>,
    #   <b><tt>"BINARY[#{part}]<#{offset}>"</tt></b> -- See #binary.
    # * <b><tt>"BINARY.SIZE[#{part}]"</tt></b> -- See #binary_size.
    #
    # Several static message attributes in
    # IMAP4rev1[https://www.rfc-editor.org/rfc/rfc3501.html] are obsolete and
    # been removed from
    # IMAP4rev2[https://www.rfc-editor.org/rfc/rfc9051.html]:
    #
    # * <b><tt>"RFC822"</tt></b> --- See #rfc822 or replace with
    #   <tt>"BODY[]"</tt> and #message.
    # * <b><tt>"RFC822.HEADER"</tt></b> --- See #rfc822_header or replace with
    #   <tt>"BODY[HEADER]"</tt> and #header.
    # * <b><tt>"RFC822.TEXT"</tt></b> --- See #rfc822_text or replace with
    #   <tt>"BODY[TEXT]"</tt> and #text.
    #
    # Net::IMAP supports static attributes defined by the following extensions:
    # * +OBJECTID+ {[RFC8474]}[https://www.rfc-editor.org/rfc/rfc8474.html]
    #   * <b><tt>"EMAILID"</tt></b> --- See #emailid.
    #   * <b><tt>"THREADID"</tt></b> --- See #threadid.
    #
    # * +X-GM-EXT-1+ {[non-standard Gmail
    #   extension]}[https://developers.google.com/gmail/imap/imap-extensions]
    #   * <b><tt>"X-GM-MSGID"</tt></b> --- unique message ID.  Access via #attr.
    #   * <b><tt>"X-GM-THRID"</tt></b> --- Thread ID.  Access via #attr.
    #
    # [Note:]
    #   >>>
    #     Additional static fields are defined in other \IMAP extensions, but
    #     Net::IMAP can't parse them yet.
    #
    # ==== Dynamic message attributes
    #
    # Some message attributes can be dynamically changed, for example using the
    # {STORE command}[rdoc-ref:Net::IMAP#store].
    #
    # The only dynamic message attribute defined by
    # IMAP4rev1[https://www.rfc-editor.org/rfc/rfc3501.html] and
    # IMAP4rev2[https://www.rfc-editor.org/rfc/rfc9051.html] is:
    #
    # * <b><tt>"FLAGS"</tt></b> --- See #flags.
    #
    # Net::IMAP supports dynamic attributes defined by the following extensions:
    #
    # * +CONDSTORE+ {[RFC7162]}[https://www.rfc-editor.org/rfc/rfc7162.html]:
    #   * <b><tt>"MODSEQ"</tt></b> --- See #modseq.
    # * +X-GM-EXT-1+ {[non-standard Gmail
    #   extension]}[https://developers.google.com/gmail/imap/imap-extensions]
    #   * <b><tt>"X-GM-LABELS"</tt></b> --- Gmail labels.  Access via #attr.
    #
    # [Note:]
    #   >>>
    #     Additional dynamic fields are defined in other \IMAP extensions, but
    #     Net::IMAP can't parse them yet.
    #
    # === Implicitly setting <tt>\Seen</tt> and using +PEEK+
    #
    # Unless the mailbox is has been opened as read-only, fetching
    # <tt>BODY[#{section}]</tt> or <tt>BINARY[#{section}]</tt>
    # will implicitly set the <tt>\Seen</tt> flag.  To avoid this, fetch using
    # <tt>BODY.PEEK[#{section}]</tt> or <tt>BINARY.PEEK[#{section}]</tt>
    # instead.
    #
    # Note that the data will always be _returned_ without <tt>".PEEK"</tt>, in
    # <tt>BODY[#{specifier}]</tt> or <tt>BINARY[#{section}]</tt>.
    #
    class FetchData < Struct.new(:seqno, :attr)
      ##
      # method: seqno
      # :call-seq: seqno -> Integer
      #
      # The message sequence number.
      #
      # [Note]
      #   This is never the unique identifier (UID), not even for the
      #   Net::IMAP#uid_fetch result.  The UID is available from #uid, if it was
      #   returned.

      ##
      # method: attr
      # :call-seq: attr -> hash
      #
      # Each key specifies a message attribute, and the value is the
      # corresponding data item.  Standard data items have corresponding
      # accessor methods.  The definitions of each attribute type is documented
      # on its accessor.
      #
      # >>>
      #   *Note:* #seqno is not a message attribute.

      # :call-seq: attr_upcase -> hash
      #
      # A transformation of #attr, with all the keys converted to upper case.
      #
      # Header field names are case-preserved but not case-sensitive, so this is
      # used by #header_fields and #header_fields_not.
      def attr_upcase; attr.transform_keys(&:upcase) end

      # :call-seq:
      #   body -> body structure or nil
      #
      # Returns an alternate form of #bodystructure, without any extension data.
      #
      # This is the same as getting the value for <tt>"BODY"</tt> from #attr.
      #
      # [Note]
      #   Use #message, #part, #header, #header_fields, #header_fields_not,
      #   #text, or #mime to retrieve <tt>BODY[#{section_spec}]</tt> attributes.
      def body; attr["BODY"] end

      # :call-seq:
      #   message(offset: bytes) -> string or nil
      #
      # The RFC5322[https://www.rfc-editor.org/rfc/rfc5322.html]
      # expression of the entire message, as a string.
      #
      # See #part for a description of +offset+.
      #
      # <em>RFC5322 messages can be parsed using the "mail" gem.</em>
      #
      # This is the same as getting the value for <tt>"BODY[]"</tt> or
      # <tt>"BODY[]<#{offset}>"</tt> from #attr.
      #
      # See also: #header, #text, and #mime.
      def message(offset: nil) attr[body_section_attr(offset: offset)] end

      # :call-seq:
      #   part(*part_nums, offset: bytes) -> string or nil
      #
      # The string representation of a particular MIME part.
      #
      # +part_nums+ forms a path of MIME part numbers, counting up from +1+,
      # which may specify an arbitrarily nested part, similarly to Array#dig.
      # Messages that don't use MIME, or MIME messages that are not multipart
      # and don't hold an encapsulated message, only have part +1+.
      #
      # If a zero-based +offset+ is given, the returned string is a substring of
      # the entire contents, starting at that origin octet.  This means that
      # <tt>BODY[]<0></tt> MAY be truncated, but <tt>BODY[]</tt> is never
      # truncated.
      #
      # This is the same as getting the value of
      # <tt>"BODY[#{part_nums.join(".")}]"</tt> or
      # <tt>"BODY[#{part_nums.join(".")}]<#{offset}>"</tt> from #attr.
      #
      # See also: #message, #header, #text, and #mime.
      def part(index, *subparts, offset: nil)
        attr[body_section_attr([index, *subparts], offset: offset)]
      end

      # :call-seq:
      #   header(*part_nums,                offset: nil) -> string or nil
      #   header(*part_nums, fields: names, offset: nil) -> string or nil
      #   header(*part_nums, except: names, offset: nil) -> string or nil
      #
      # The {[RFC5322]}[https://www.rfc-editor.org/rfc/rfc5322.html] header of a
      # message or of an encapsulated
      # {[MIME-IMT]}[https://www.rfc-editor.org/rfc/rfc2046.html]
      # MESSAGE/RFC822 or MESSAGE/GLOBAL message.
      #
      # <em>Headers can be parsed using the "mail" gem.</em>
      #
      # See #part for a description of +part_nums+ and +offset+.
      #
      # ==== Without +fields+ or +except+
      # This is the same as getting the value from #attr for one of:
      # * <tt>BODY[HEADER]</tt>
      # * <tt>BODY[HEADER]<#{offset}></tt>
      # * <tt>BODY[#{part_nums.join "."}.HEADER]"</tt>
      # * <tt>BODY[#{part_nums.join "."}.HEADER]<#{offset}>"</tt>
      #
      # ==== With +fields+
      # When +fields+ is sent, returns a subset of the header which contains
      # only the header fields that match one of the names in the list.
      #
      # This is the same as getting the value from #attr_upcase for one of:
      # * <tt>BODY[HEADER.FIELDS (#{names.join " "})]</tt>
      # * <tt>BODY[HEADER.FIELDS (#{names.join " "})]<#{offset}></tt>
      # * <tt>BODY[#{part_nums.join "."}.HEADER.FIELDS (#{names.join " "})]</tt>
      # * <tt>BODY[#{part_nums.join "."}.HEADER.FIELDS (#{names.join " "})]<#{offset}></tt>
      #
      # See also: #header_fields
      #
      # ==== With +except+
      # When +except+ is sent, returns a subset of the header which contains
      # only the header fields that do _not_ match one of the names in the list.
      #
      # This is the same as getting the value from #attr_upcase for one of:
      # * <tt>BODY[HEADER.FIELDS.NOT (#{names.join " "})]</tt>
      # * <tt>BODY[HEADER.FIELDS.NOT (#{names.join " "})]<#{offset}></tt>
      # * <tt>BODY[#{part_nums.join "."}.HEADER.FIELDS.NOT (#{names.join " "})]</tt>
      # * <tt>BODY[#{part_nums.join "."}.HEADER.FIELDS.NOT (#{names.join " "})]<#{offset}></tt>
      #
      # See also: #header_fields_not
      def header(*part_nums, fields: nil, except: nil, offset: nil)
        fields && except and
          raise ArgumentError, "conflicting 'fields' and 'except' arguments"
        if fields
          text = "HEADER.FIELDS (%s)"     % [fields.join(" ").upcase]
          attr_upcase[body_section_attr(part_nums, text, offset: offset)]
        elsif except
          text = "HEADER.FIELDS.NOT (%s)" % [except.join(" ").upcase]
          attr_upcase[body_section_attr(part_nums, text, offset: offset)]
        else
          attr[body_section_attr(part_nums, "HEADER", offset: offset)]
        end
      end

      # :call-seq:
      #   header_fields(*names, part: [], offset: nil) -> string or nil
      #
      # The result from #header when called with <tt>fields: names</tt>.
      def header_fields(first, *rest, part: [], offset: nil)
        header(*part, fields: [first, *rest], offset: offset)
      end

      # :call-seq:
      #   header_fields_not(*names, part: [], offset: nil) -> string or nil
      #
      # The result from #header when called with <tt>except: names</tt>.
      def header_fields_not(first, *rest, part: [], offset: nil)
        header(*part, except: [first, *rest], offset: offset)
      end

      # :call-seq:
      #   mime(*part_nums)                -> string or nil
      #   mime(*part_nums, offset: bytes) -> string or nil
      #
      # The {[MIME-IMB]}[https://www.rfc-editor.org/rfc/rfc2045.html] header for
      # a message part, if it was fetched.
      #
      # See #part for a description of +part_nums+ and +offset+.
      #
      # This is the same as getting the value for
      # <tt>"BODY[#{part_nums}.MIME]"</tt> or
      # <tt>"BODY[#{part_nums}.MIME]<#{offset}>"</tt> from #attr.
      #
      # See also: #message, #header, and #text.
      def mime(part, *subparts, offset: nil)
        attr[body_section_attr([part, *subparts], "MIME", offset: offset)]
      end

      # :call-seq:
      #   text(*part_nums)                -> string or nil
      #   text(*part_nums, offset: bytes) -> string or nil
      #
      # The text body of a message or a message part, if it was fetched,
      # omitting the {[RFC5322]}[https://www.rfc-editor.org/rfc/rfc5322.html]
      # header.
      #
      # See #part for a description of +part_nums+ and +offset+.
      #
      # This is the same as getting the value from #attr for one of:
      # * <tt>"BODY[TEXT]"</tt>,
      # * <tt>"BODY[TEXT]<#{offset}>"</tt>,
      # * <tt>"BODY[#{section}.TEXT]"</tt>, or
      # * <tt>"BODY[#{section}.TEXT]<#{offset}>"</tt>.
      #
      # See also: #message, #header, and #mime.
      def text(*part, offset: nil)
        attr[body_section_attr(part, "TEXT", offset: offset)]
      end

      # :call-seq:
      #   bodystructure -> BodyStructure struct or nil
      #
      # A BodyStructure object that describes the message, if it was fetched.
      #
      # This is the same as getting the value for <tt>"BODYSTRUCTURE"</tt> from
      # #attr.
      def bodystructure; attr["BODYSTRUCTURE"] end
      alias body_structure bodystructure

      # :call-seq: envelope -> Envelope or nil
      #
      # An Envelope object that describes the envelope structure of a message.
      # See the documentation for Envelope for a description of the envelope
      # structure attributes.
      #
      # This is the same as getting the value for <tt>"ENVELOPE"</tt> from
      # #attr.
      def envelope; attr["ENVELOPE"] end

      # :call-seq: flags -> array of Symbols and Strings
      #
      # A array of flags that are set for this message.  System flags are
      # symbols that have been capitalized by String#capitalize.  Keyword flags
      # are strings and their case is not changed.
      #
      # This is the same as getting the value for <tt>"FLAGS"</tt> from #attr.
      #
      # [Note]
      #   The +FLAGS+ field is dynamic, and can change for a uniquely identified
      #   message.
      def flags; attr["FLAGS"] end

      # :call-seq: internaldate -> Time or nil
      #
      # The internal date and time of the message on the server.  This is not
      # the date and time in the [RFC5322[https://tools.ietf.org/html/rfc5322]]
      # header, but rather a date and time which reflects when the message was
      # received.
      #
      # This is similar to getting the value for <tt>"INTERNALDATE"</tt> from
      # #attr.
      #
      # [Note]
      #   <tt>attr["INTERNALDATE"]</tt> returns a string, and this method
      #   returns a Time object.
      def internaldate
        attr["INTERNALDATE"]&.then { IMAP.decode_time _1 }
      end
      alias internal_date internaldate

      # :call-seq: rfc822 -> String
      #
      # Semantically equivalent to #message with no arguments.
      #
      # This is the same as getting the value for <tt>"RFC822"</tt> from #attr.
      #
      # [Note]
      #   +IMAP4rev2+ deprecates <tt>RFC822</tt>.
      def rfc822; attr["RFC822"] end

      # :call-seq: rfc822_size -> Integer
      #
      # A number expressing the [RFC5322[https://tools.ietf.org/html/rfc5322]]
      # size of the message.
      #
      # This is the same as getting the value for <tt>"RFC822.SIZE"</tt> from
      # #attr.
      #
      # [Note]
      #   \IMAP was originally developed for the older
      #   RFC822[https://www.rfc-editor.org/rfc/rfc822.html] standard, and as a
      #   consequence several fetch items in \IMAP incorporate "RFC822" in their
      #   name.  With the exception of +RFC822.SIZE+, there are more modern
      #   replacements; for example, the modern version of +RFC822.HEADER+ is
      #   <tt>BODY.PEEK[HEADER]</tt>.  In all cases, "RFC822" should be
      #   interpreted as a reference to the updated
      #   RFC5322[https://www.rfc-editor.org/rfc/rfc5322.html] standard.
      def rfc822_size; attr["RFC822.SIZE"] end
      alias size rfc822_size

      # :call-seq: rfc822_header -> String
      #
      # Semantically equivalent to #header, with no arguments.
      #
      # This is the same as getting the value for <tt>"RFC822.HEADER"</tt> from #attr.
      #
      # [Note]
      #   +IMAP4rev2+ deprecates <tt>RFC822.HEADER</tt>.
      def rfc822_header; attr["RFC822.HEADER"] end

      # :call-seq: rfc822_text -> String
      #
      # Semantically equivalent to #text, with no arguments.
      #
      # This is the same as getting the value for <tt>"RFC822.TEXT"</tt> from
      # #attr.
      #
      # [Note]
      #   +IMAP4rev2+ deprecates <tt>RFC822.TEXT</tt>.
      def rfc822_text; attr["RFC822.TEXT"] end

      # :call-seq: uid -> Integer
      #
      # A number expressing the unique identifier of the message.
      #
      # This is the same as getting the value for <tt>"UID"</tt> from #attr.
      def uid; attr["UID"] end

      # :call-seq:
      #   binary(*part_nums, offset: nil) -> string or nil
      #
      # Returns the binary representation of a particular MIME part, which has
      # already been decoded according to its Content-Transfer-Encoding.
      #
      # See #part for a description of +part_nums+ and +offset+.
      #
      # This is the same as getting the value of
      # <tt>"BINARY[#{part_nums.join(".")}]"</tt> or
      # <tt>"BINARY[#{part_nums.join(".")}]<#{offset}>"</tt> from #attr.
      #
      # The server must support either
      # IMAP4rev2[https://www.rfc-editor.org/rfc/rfc9051.html]
      # or the +BINARY+ extension
      # {[RFC3516]}[https://www.rfc-editor.org/rfc/rfc3516.html].
      #
      # See also: #binary_size, #mime
      def binary(*part_nums, offset: nil)
        attr[section_attr("BINARY", part_nums, offset: offset)]
      end

      # :call-seq:
      #   binary_size(*part_nums) -> integer or nil
      #
      # Returns the decoded size of a particular MIME part (the size to expect
      # in response to a <tt>BINARY</tt> fetch request).
      #
      # See #part for a description of +part_nums+.
      #
      # This is the same as getting the value of
      # <tt>"BINARY.SIZE[#{part_nums.join(".")}]"</tt> from #attr.
      #
      # The server must support either
      # IMAP4rev2[https://www.rfc-editor.org/rfc/rfc9051.html]
      # or the +BINARY+ extension
      # {[RFC3516]}[https://www.rfc-editor.org/rfc/rfc3516.html].
      #
      # See also: #binary, #mime
      def binary_size(*part_nums)
        attr[section_attr("BINARY.SIZE", part_nums)]
      end

      # :call-seq: modseq -> Integer
      #
      # The modification sequence number associated with this IMAP message.
      #
      # This is the same as getting the value for <tt>"MODSEQ"</tt> from #attr.
      #
      # The server must support the +CONDSTORE+ extension
      # {[RFC7162]}[https://www.rfc-editor.org/rfc/rfc7162.html].
      #
      # [Note]
      #   The +MODSEQ+ field is dynamic, and can change for a uniquely
      #   identified message.
      def modseq; attr["MODSEQ"] end

      # :call-seq: emailid -> string or nil
      #
      # An ObjectID that uniquely identifies the immutable content of a single
      # message.
      #
      # The server must return the same +EMAILID+ for both the source and
      # destination messages after a COPY or MOVE command.  However, it is
      # possible for different messages with the same EMAILID to have different
      # mutable attributes, such as flags.
      #
      # This is the same as getting the value for <tt>"EMAILID"</tt> from
      # #attr.
      #
      # The server must support the +OBJECTID+ extension
      # {[RFC8474]}[https://www.rfc-editor.org/rfc/rfc8474.html].
      def emailid; attr["EMAILID"] end

      # :call-seq: threadid -> string or nil
      #
      # An ObjectID that uniquely identifies a set of messages that the server
      # believes should be grouped together.
      #
      # It is generally based on some combination of References, In-Reply-To,
      # and Subject, but the exact implementation is left up to the server
      # implementation.  The server should return the same thread identifier for
      # related messages, even if they are in different mailboxes.
      #
      # This is the same as getting the value for <tt>"THREADID"</tt> from
      # #attr.
      #
      # The server must support the +OBJECTID+ extension
      # {[RFC8474]}[https://www.rfc-editor.org/rfc/rfc8474.html].
      def threadid; attr["THREADID"] end

      private

      def body_section_attr(...) section_attr("BODY", ...) end

      def section_attr(attr, part = [], text = nil, offset: nil)
        spec = Array(part).flatten.map { Integer(_1) }
        spec << text if text
        spec = spec.join(".")
        if offset then "%s[%s]<%d>" % [attr, spec, Integer(offset)]
        else           "%s[%s]"     % [attr, spec]
        end
      end

    end
  end
end
