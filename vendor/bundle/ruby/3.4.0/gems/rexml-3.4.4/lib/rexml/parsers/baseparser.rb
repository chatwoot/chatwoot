# frozen_string_literal: true
require_relative '../parseexception'
require_relative '../undefinednamespaceexception'
require_relative '../security'
require_relative '../source'
require 'set'
require "strscan"

module REXML
  module Parsers
    unless [].respond_to?(:tally)
      module EnumerableTally
        refine Enumerable do
          def tally
            counts = {}
            each do |item|
              counts[item] ||= 0
              counts[item] += 1
            end
            counts
          end
        end
      end
      using EnumerableTally
    end

    if StringScanner::Version < "3.0.8"
      module StringScannerCaptures
        refine StringScanner do
          def captures
            values_at(*(1...size))
          end
        end
      end
      using StringScannerCaptures
    end

    # = Using the Pull Parser
    # <em>This API is experimental, and subject to change.</em>
    #  parser = PullParser.new( "<a>text<b att='val'/>txet</a>" )
    #  while parser.has_next?
    #    res = parser.next
    #    puts res[1]['att'] if res.start_tag? and res[0] == 'b'
    #  end
    # See the PullEvent class for information on the content of the results.
    # The data is identical to the arguments passed for the various events to
    # the StreamListener API.
    #
    # Notice that:
    #  parser = PullParser.new( "<a>BAD DOCUMENT" )
    #  while parser.has_next?
    #    res = parser.next
    #    raise res[1] if res.error?
    #  end
    #
    # Nat Price gave me some good ideas for the API.
    class BaseParser
      LETTER = '[:alpha:]'
      DIGIT = '[:digit:]'

      COMBININGCHAR = '' # TODO
      EXTENDER = ''      # TODO

      NCNAME_STR= "[#{LETTER}_][-[:alnum:]._#{COMBININGCHAR}#{EXTENDER}]*"
      QNAME_STR= "(?:(#{NCNAME_STR}):)?(#{NCNAME_STR})"
      QNAME = /(#{QNAME_STR})/

      # Just for backward compatibility. For example, kramdown uses this.
      # It's not used in REXML.
      UNAME_STR= "(?:#{NCNAME_STR}:)?#{NCNAME_STR}"

      NAMECHAR = '[\-\w\.:]'
      NAME = "([\\w:]#{NAMECHAR}*)"
      NMTOKEN = "(?:#{NAMECHAR})+"
      NMTOKENS = "#{NMTOKEN}(\\s+#{NMTOKEN})*"
      REFERENCE = "&(?:#{NAME};|#\\d+;|#x[0-9a-fA-F]+;)"
      REFERENCE_RE = /#{REFERENCE}/

      DOCTYPE_START = /\A\s*<!DOCTYPE\s/um
      DOCTYPE_END = /\A\s*\]\s*>/um
      ATTRIBUTE_PATTERN = /\s*(#{QNAME_STR})\s*=\s*(["'])(.*?)\4/um
      COMMENT_START = /\A<!--/u
      COMMENT_PATTERN = /<!--(.*?)-->/um
      CDATA_START = /\A<!\[CDATA\[/u
      CDATA_END = /\A\s*\]\s*>/um
      CDATA_PATTERN = /<!\[CDATA\[(.*?)\]\]>/um
      XMLDECL_START = /\A<\?xml\s/u;
      XMLDECL_PATTERN = /<\?xml\s+(.*?)\?>/um
      INSTRUCTION_START = /\A<\?/u
      INSTRUCTION_PATTERN = /<\?#{NAME}(\s+.*?)?\?>/um
      TAG_MATCH = /\A<((?>#{QNAME_STR}))/um
      CLOSE_MATCH = /\A\s*<\/(#{QNAME_STR})\s*>/um

      VERSION = /\bversion\s*=\s*["'](.*?)['"]/um
      ENCODING = /\bencoding\s*=\s*["'](.*?)['"]/um
      STANDALONE = /\bstandalone\s*=\s*["'](.*?)['"]/um

      ENTITY_START = /\A\s*<!ENTITY/
      ELEMENTDECL_START = /\A\s*<!ELEMENT/um
      ELEMENTDECL_PATTERN = /\A\s*(<!ELEMENT.*?)>/um
      SYSTEMENTITY = /\A\s*(%.*?;)\s*$/um
      ENUMERATION = "\\(\\s*#{NMTOKEN}(?:\\s*\\|\\s*#{NMTOKEN})*\\s*\\)"
      NOTATIONTYPE = "NOTATION\\s+\\(\\s*#{NAME}(?:\\s*\\|\\s*#{NAME})*\\s*\\)"
      ENUMERATEDTYPE = "(?:(?:#{NOTATIONTYPE})|(?:#{ENUMERATION}))"
      ATTTYPE = "(CDATA|ID|IDREF|IDREFS|ENTITY|ENTITIES|NMTOKEN|NMTOKENS|#{ENUMERATEDTYPE})"
      ATTVALUE = "(?:\"((?:[^<&\"]|#{REFERENCE})*)\")|(?:'((?:[^<&']|#{REFERENCE})*)')"
      DEFAULTDECL = "(#REQUIRED|#IMPLIED|(?:(#FIXED\\s+)?#{ATTVALUE}))"
      ATTDEF = "\\s+#{NAME}\\s+#{ATTTYPE}\\s+#{DEFAULTDECL}"
      ATTDEF_RE = /#{ATTDEF}/
      ATTLISTDECL_START = /\A\s*<!ATTLIST/um
      ATTLISTDECL_PATTERN = /\A\s*<!ATTLIST\s+#{NAME}(?:#{ATTDEF})*\s*>/um

      TEXT_PATTERN = /\A([^<]*)/um

      # Entity constants
      PUBIDCHAR = "\x20\x0D\x0Aa-zA-Z0-9\\-()+,./:=?;!*@$_%#"
      SYSTEMLITERAL = %Q{((?:"[^"]*")|(?:'[^']*'))}
      PUBIDLITERAL = %Q{("[#{PUBIDCHAR}']*"|'[#{PUBIDCHAR}]*')}
      EXTERNALID = "(?:(?:(SYSTEM)\\s+#{SYSTEMLITERAL})|(?:(PUBLIC)\\s+#{PUBIDLITERAL}\\s+#{SYSTEMLITERAL}))"
      NDATADECL = "\\s+NDATA\\s+#{NAME}"
      PEREFERENCE = "%#{NAME};"
      ENTITYVALUE = %Q{((?:"(?:[^%&"]|#{PEREFERENCE}|#{REFERENCE})*")|(?:'([^%&']|#{PEREFERENCE}|#{REFERENCE})*'))}
      PEDEF = "(?:#{ENTITYVALUE}|#{EXTERNALID})"
      ENTITYDEF = "(?:#{ENTITYVALUE}|(?:#{EXTERNALID}(#{NDATADECL})?))"
      PEDECL = "<!ENTITY\\s+(%)\\s+#{NAME}\\s+#{PEDEF}\\s*>"
      GEDECL = "<!ENTITY\\s+#{NAME}\\s+#{ENTITYDEF}\\s*>"
      ENTITYDECL = /\s*(?:#{GEDECL})|\s*(?:#{PEDECL})/um

      NOTATIONDECL_START = /\A\s*<!NOTATION/um
      EXTERNAL_ID_PUBLIC = /\A\s*PUBLIC\s+#{PUBIDLITERAL}\s+#{SYSTEMLITERAL}\s*/um
      EXTERNAL_ID_SYSTEM = /\A\s*SYSTEM\s+#{SYSTEMLITERAL}\s*/um
      PUBLIC_ID = /\A\s*PUBLIC\s+#{PUBIDLITERAL}\s*/um

      EREFERENCE = /&(?!#{NAME};)/

      DEFAULT_ENTITIES = {
        'gt' => [/&gt;/, '&gt;', '>', />/],
        'lt' => [/&lt;/, '&lt;', '<', /</],
        'quot' => [/&quot;/, '&quot;', '"', /"/],
        "apos" => [/&apos;/, "&apos;", "'", /'/]
      }

      module Private
        PEREFERENCE_PATTERN = /#{PEREFERENCE}/um
        TAG_PATTERN = /((?>#{QNAME_STR}))\s*/um
        CLOSE_PATTERN = /(#{QNAME_STR})\s*>/um
        EQUAL_PATTERN = /\s*=\s*/um
        ATTLISTDECL_END = /\s+#{NAME}(?:#{ATTDEF})*\s*>/um
        NAME_PATTERN = /#{NAME}/um
        GEDECL_PATTERN = "\\s+#{NAME}\\s+#{ENTITYDEF}\\s*>"
        PEDECL_PATTERN = "\\s+(%)\\s+#{NAME}\\s+#{PEDEF}\\s*>"
        ENTITYDECL_PATTERN = /(?:#{GEDECL_PATTERN})|(?:#{PEDECL_PATTERN})/um
        CARRIAGE_RETURN_NEWLINE_PATTERN = /\r\n?/
        CHARACTER_REFERENCES = /&#((?:\d+)|(?:x[a-fA-F0-9]+));/
        DEFAULT_ENTITIES_PATTERNS = {}
        default_entities = ['gt', 'lt', 'quot', 'apos', 'amp']
        default_entities.each do |term|
          DEFAULT_ENTITIES_PATTERNS[term] = /&#{term};/
        end
        XML_PREFIXED_NAMESPACE = "http://www.w3.org/XML/1998/namespace"
      end
      private_constant :Private

      def initialize( source )
        self.stream = source
        @listeners = []
        @prefixes = Set.new
        @entity_expansion_count = 0
        @entity_expansion_limit = Security.entity_expansion_limit
        @entity_expansion_text_limit = Security.entity_expansion_text_limit
        @source.ensure_buffer
        @version = nil
      end

      def add_listener( listener )
        @listeners << listener
      end

      attr_reader :source
      attr_reader :entity_expansion_count
      attr_writer :entity_expansion_limit
      attr_writer :entity_expansion_text_limit

      def stream=( source )
        @source = SourceFactory.create_from( source )
        reset
      end

      def reset
        @closed = nil
        @have_root = false
        @document_status = nil
        @tags = []
        @stack = []
        @entities = []
        @namespaces = {"xml" => Private::XML_PREFIXED_NAMESPACE}
        @namespaces_restore_stack = []
      end

      def position
        if @source.respond_to? :position
          @source.position
        else
          # FIXME
          0
        end
      end

      # Returns true if there are no more events
      def empty?
        (@source.empty? and @stack.empty?)
      end

      # Returns true if there are more events.  Synonymous with !empty?
      def has_next?
        !(@source.empty? and @stack.empty?)
      end

      # Push an event back on the head of the stream.  This method
      # has (theoretically) infinite depth.
      def unshift token
        @stack.unshift(token)
      end

      # Peek at the +depth+ event in the stack.  The first element on the stack
      # is at depth 0.  If +depth+ is -1, will parse to the end of the input
      # stream and return the last event, which is always :end_document.
      # Be aware that this causes the stream to be parsed up to the +depth+
      # event, so you can effectively pre-parse the entire document (pull the
      # entire thing into memory) using this method.
      def peek depth=0
        raise %Q[Illegal argument "#{depth}"] if depth < -1
        temp = []
        if depth == -1
          temp.push(pull()) until empty?
        else
          while @stack.size+temp.size < depth+1
            temp.push(pull())
          end
        end
        @stack += temp if temp.size > 0
        @stack[depth]
      end

      # Returns the next event.  This is a +PullEvent+ object.
      def pull
        @source.drop_parsed_content

        pull_event.tap do |event|
          @listeners.each do |listener|
            listener.receive event
          end
        end
      end

      def pull_event
        if @closed
          x, @closed = @closed, nil
          return [ :end_element, x ]
        end
        if empty?
          if @document_status == :in_doctype
            raise ParseException.new("Malformed DOCTYPE: unclosed", @source)
          end
          unless @tags.empty?
            path = "/" + @tags.join("/")
            raise ParseException.new("Missing end tag for '#{path}'", @source)
          end

          unless @document_status == :in_element
            raise ParseException.new("Malformed XML: No root element", @source)
          end

          return [ :end_document ]
        end
        return @stack.shift if @stack.size > 0
        #STDERR.puts @source.encoding
        #STDERR.puts "BUFFER = #{@source.buffer.inspect}"

        @source.ensure_buffer
        if @document_status == nil
          start_position = @source.position
          if @source.match?("<?", true)
            return process_instruction
          elsif @source.match?("<!", true)
            if @source.match?("--", true)
              return [ :comment, process_comment ]
            elsif @source.match?("DOCTYPE", true)
              base_error_message = "Malformed DOCTYPE"
              unless @source.skip_spaces
                if @source.match?(">")
                  message = "#{base_error_message}: name is missing"
                else
                  message = "#{base_error_message}: invalid name"
                end
                @source.position = start_position
                raise REXML::ParseException.new(message, @source)
              end
              name = parse_name(base_error_message)
              @source.skip_spaces
              if @source.match?("[", true)
                id = [nil, nil, nil]
                @document_status = :in_doctype
              elsif @source.match?(">", true)
                id = [nil, nil, nil]
                @document_status = :after_doctype
                @source.ensure_buffer
              else
                id = parse_id(base_error_message,
                              accept_external_id: true,
                              accept_public_id: false)
                if id[0] == "SYSTEM"
                  # For backward compatibility
                  id[1], id[2] = id[2], nil
                end
                @source.skip_spaces
                if @source.match?("[", true)
                  @document_status = :in_doctype
                elsif @source.match?(">", true)
                  @document_status = :after_doctype
                  @source.ensure_buffer
                else
                  message = "#{base_error_message}: garbage after external ID"
                  raise REXML::ParseException.new(message, @source)
                end
              end
              args = [:start_doctype, name, *id]
              if @document_status == :after_doctype
                @source.skip_spaces
                @stack << [ :end_doctype ]
              end
              return args
            else
              message = "Invalid XML"
              raise REXML::ParseException.new(message, @source)
            end
          end
        end
        if @document_status == :in_doctype
          @source.skip_spaces
          start_position = @source.position
          if @source.match?("<!", true)
            if @source.match?("ELEMENT", true)
              md = @source.match(/(.*?)>/um, true)
              raise REXML::ParseException.new( "Bad ELEMENT declaration!", @source ) if md.nil?
              return [ :elementdecl, "<!ELEMENT" + md[1] ]
            elsif @source.match?("ENTITY", true)
              match_data = @source.match(Private::ENTITYDECL_PATTERN, true)
              unless match_data
                raise REXML::ParseException.new("Malformed entity declaration", @source)
              end
              match = [:entitydecl, *match_data.captures.compact]
              ref = false
              if match[1] == '%'
                ref = true
                match.delete_at 1
              end
              # Now we have to sort out what kind of entity reference this is
              if match[2] == 'SYSTEM'
                # External reference
                match[3] = match[3][1..-2] # PUBID
                match.delete_at(4) if match.size > 4 # Chop out NDATA decl
                # match is [ :entity, name, SYSTEM, pubid(, ndata)? ]
              elsif match[2] == 'PUBLIC'
                # External reference
                match[3] = match[3][1..-2] # PUBID
                match[4] = match[4][1..-2] # HREF
                match.delete_at(5) if match.size > 5 # Chop out NDATA decl
                # match is [ :entity, name, PUBLIC, pubid, href(, ndata)? ]
              elsif Private::PEREFERENCE_PATTERN.match?(match[2])
                raise REXML::ParseException.new("Parameter entity references forbidden in internal subset: #{match[2]}", @source)
              else
                match[2] = match[2][1..-2]
                match.pop if match.size == 4
                # match is [ :entity, name, value ]
              end
              match << '%' if ref
              return match
            elsif @source.match?("ATTLIST", true)
              md = @source.match(Private::ATTLISTDECL_END, true)
              raise REXML::ParseException.new( "Bad ATTLIST declaration!", @source ) if md.nil?
              element = md[1]
              contents = "<!ATTLIST" + md[0]

              pairs = {}
              values = md[0].strip.scan( ATTDEF_RE )
              values.each do |attdef|
                unless attdef[3] == "#IMPLIED"
                  attdef.compact!
                  val = attdef[3]
                  val = attdef[4] if val == "#FIXED "
                  pairs[attdef[0]] = val
                  if attdef[0] =~ /^xmlns:(.*)/
                    @namespaces[$1] = val
                  end
                end
              end
              return [ :attlistdecl, element, pairs, contents ]
            elsif @source.match?("NOTATION", true)
              base_error_message = "Malformed notation declaration"
              unless @source.skip_spaces
                if @source.match?(">")
                  message = "#{base_error_message}: name is missing"
                else
                  message = "#{base_error_message}: invalid name"
                end
                @source.position = start_position
                raise REXML::ParseException.new(message, @source)
              end
              name = parse_name(base_error_message)
              id = parse_id(base_error_message,
                            accept_external_id: true,
                            accept_public_id: true)
              @source.skip_spaces
              unless @source.match?(">", true)
                message = "#{base_error_message}: garbage before end >"
                raise REXML::ParseException.new(message, @source)
              end
              return [:notationdecl, name, *id]
            elsif @source.match?("--", true)
              return [ :comment, process_comment ]
            else
              raise REXML::ParseException.new("Malformed node: Started with '<!' but not a comment nor ELEMENT,ENTITY,ATTLIST,NOTATION", @source)
            end
          elsif match = @source.match(/(%.*?;)\s*/um, true)
            return [ :externalentity, match[1] ]
          elsif @source.match?(/\]\s*>/um, true)
            @document_status = :after_doctype
            return [ :end_doctype ]
          else
            raise ParseException.new("Malformed DOCTYPE: invalid declaration", @source)
          end
        end
        if @document_status == :after_doctype
          @source.skip_spaces
        end
        begin
          start_position = @source.position
          if @source.match?("<", true)
            # :text's read_until may remain only "<" in buffer. In the
            # case, buffer is empty here. So we need to fill buffer
            # here explicitly.
            @source.ensure_buffer
            if @source.match?("/", true)
              @namespaces_restore_stack.pop
              last_tag = @tags.pop
              md = @source.match(Private::CLOSE_PATTERN, true)
              if md and !last_tag
                message = "Unexpected top-level end tag (got '#{md[1]}')"
                raise REXML::ParseException.new(message, @source)
              end
              if md.nil? or last_tag != md[1]
                message = "Missing end tag for '#{last_tag}'"
                message += " (got '#{md[1]}')" if md
                @source.position = start_position if md.nil?
                raise REXML::ParseException.new(message, @source)
              end
              return [ :end_element, last_tag ]
            elsif @source.match?("!", true)
              #STDERR.puts "SOURCE BUFFER = #{source.buffer}, #{source.buffer.size}"
              if @source.match?("--", true)
                return [ :comment, process_comment ]
              elsif @source.match?("[CDATA[", true)
                text = @source.read_until("]]>")
                if text.chomp!("]]>")
                  return [ :cdata, text ]
                else
                  raise REXML::ParseException.new("Malformed CDATA: Missing end ']]>'", @source)
                end
              else
                raise REXML::ParseException.new("Malformed node: Started with '<!' but not a comment nor CDATA", @source)
              end
            elsif @source.match?("?", true)
              return process_instruction
            else
              # Get the next tag
              md = @source.match(Private::TAG_PATTERN, true)
              unless md
                @source.position = start_position
                raise REXML::ParseException.new("malformed XML: missing tag start", @source)
              end
              tag = md[1]
              @document_status = :in_element
              @prefixes.clear
              @prefixes << md[2] if md[2]
              push_namespaces_restore
              attributes, closed = parse_attributes(@prefixes)
              # Verify that all of the prefixes have been defined
              for prefix in @prefixes
                unless @namespaces.key?(prefix)
                  raise UndefinedNamespaceException.new(prefix,@source,self)
                end
              end

              if closed
                @closed = tag
                pop_namespaces_restore
              else
                if @tags.empty? and @have_root
                  raise ParseException.new("Malformed XML: Extra tag at the end of the document (got '<#{tag}')", @source)
                end
                @tags.push( tag )
              end
              @have_root = true
              return [ :start_element, tag, attributes ]
            end
          else
            text = @source.read_until("<")
            if text.chomp!("<")
              @source.position -= "<".bytesize
            end
            if @tags.empty?
              unless /\A\s*\z/.match?(text)
                if @have_root
                  raise ParseException.new("Malformed XML: Extra content at the end of the document (got '#{text}')", @source)
                else
                  raise ParseException.new("Malformed XML: Content at the start of the document (got '#{text}')", @source)
                end
              end
              return pull_event if @have_root
            end
            return [ :text, text ]
          end
        rescue REXML::UndefinedNamespaceException
          raise
        rescue REXML::ParseException
          raise
        rescue => error
          raise REXML::ParseException.new( "Exception parsing",
            @source, self, (error ? error : $!) )
        end
        # NOTE: The end of the method never runs, because it is unreachable.
        #       All branches of code above have explicit unconditional return or raise statements.
      end
      private :pull_event

      def entity( reference, entities )
        return unless entities

        value = entities[ reference ]
        return if value.nil?

        record_entity_expansion
        unnormalize( value, entities )
      end

      # Escapes all possible entities
      def normalize( input, entities=nil, entity_filter=nil )
        copy = input.clone
        # Doing it like this rather than in a loop improves the speed
        copy.gsub!( EREFERENCE, '&amp;' )
        entities.each do |key, value|
          copy.gsub!( value, "&#{key};" ) unless entity_filter and
                                      entity_filter.include?(entity)
        end if entities
        copy.gsub!( EREFERENCE, '&amp;' )
        DEFAULT_ENTITIES.each do |key, value|
          copy.gsub!( value[3], value[1] )
        end
        copy
      end

      # Unescapes all possible entities
      def unnormalize( string, entities=nil, filter=nil )
        if string.include?("\r")
          rv = string.gsub( Private::CARRIAGE_RETURN_NEWLINE_PATTERN, "\n" )
        else
          rv = string.dup
        end
        matches = rv.scan( REFERENCE_RE )
        return rv if matches.size == 0
        rv.gsub!( Private::CHARACTER_REFERENCES ) {
          m=$1
          if m.start_with?("x")
            code_point = Integer(m[1..-1], 16)
          else
            code_point = Integer(m, 10)
          end
          [code_point].pack('U*')
        }
        matches.collect!{|x|x[0]}.compact!
        if filter
          matches.reject! do |entity_reference|
            filter.include?(entity_reference)
          end
        end
        if matches.size > 0
          matches.tally.each do |entity_reference, n|
            entity_expansion_count_before = @entity_expansion_count
            entity_value = entity( entity_reference, entities )
            if entity_value
              if n > 1
                entity_expansion_count_delta =
                  @entity_expansion_count - entity_expansion_count_before
                record_entity_expansion(entity_expansion_count_delta * (n - 1))
              end
              re = Private::DEFAULT_ENTITIES_PATTERNS[entity_reference] || /&#{entity_reference};/
              rv.gsub!( re, entity_value )
              if rv.bytesize > @entity_expansion_text_limit
                raise "entity expansion has grown too large"
              end
            else
              er = DEFAULT_ENTITIES[entity_reference]
              rv.gsub!( er[0], er[2] ) if er
            end
          end
          rv.gsub!( Private::DEFAULT_ENTITIES_PATTERNS['amp'], '&' )
        end
        rv
      end

      private
      def add_namespace(prefix, uri)
        @namespaces_restore_stack.last[prefix] = @namespaces[prefix]
        if uri.nil?
          @namespaces.delete(prefix)
        else
          @namespaces[prefix] = uri
        end
      end

      def push_namespaces_restore
        namespaces_restore = {}
        @namespaces_restore_stack.push(namespaces_restore)
        namespaces_restore
      end

      def pop_namespaces_restore
        namespaces_restore = @namespaces_restore_stack.pop
        namespaces_restore.each do |prefix, uri|
          if uri.nil?
            @namespaces.delete(prefix)
          else
            @namespaces[prefix] = uri
          end
        end
      end

      def record_entity_expansion(delta=1)
        @entity_expansion_count += delta
        if @entity_expansion_count > @entity_expansion_limit
          raise "number of entity expansions exceeded, processing aborted."
        end
      end

      def need_source_encoding_update?(xml_declaration_encoding)
        return false if xml_declaration_encoding.nil?
        return false if /\AUTF-16\z/i =~ xml_declaration_encoding
        true
      end

      def normalize_xml_declaration_encoding(xml_declaration_encoding)
        /\AUTF-16(?:BE|LE)\z/i.match?(xml_declaration_encoding) ? "UTF-16" : nil
      end

      def parse_name(base_error_message)
        md = @source.match(Private::NAME_PATTERN, true)
        unless md
          if @source.match?(/\S/um)
            message = "#{base_error_message}: invalid name"
          else
            message = "#{base_error_message}: name is missing"
          end
          raise REXML::ParseException.new(message, @source)
        end
        md[0]
      end

      def parse_id(base_error_message,
                   accept_external_id:,
                   accept_public_id:)
        if accept_external_id and (md = @source.match(EXTERNAL_ID_PUBLIC, true))
          pubid = system = nil
          pubid_literal = md[1]
          pubid = pubid_literal[1..-2] if pubid_literal # Remove quote
          system_literal = md[2]
          system = system_literal[1..-2] if system_literal # Remove quote
          ["PUBLIC", pubid, system]
        elsif accept_public_id and (md = @source.match(PUBLIC_ID, true))
          pubid = system = nil
          pubid_literal = md[1]
          pubid = pubid_literal[1..-2] if pubid_literal # Remove quote
          ["PUBLIC", pubid, nil]
        elsif accept_external_id and (md = @source.match(EXTERNAL_ID_SYSTEM, true))
          system = nil
          system_literal = md[1]
          system = system_literal[1..-2] if system_literal # Remove quote
          ["SYSTEM", nil, system]
        else
          details = parse_id_invalid_details(accept_external_id: accept_external_id,
                                             accept_public_id: accept_public_id)
          message = "#{base_error_message}: #{details}"
          raise REXML::ParseException.new(message, @source)
        end
      end

      def parse_id_invalid_details(accept_external_id:,
                                   accept_public_id:)
        public = /\A\s*PUBLIC/um
        system = /\A\s*SYSTEM/um
        if (accept_external_id or accept_public_id) and @source.match?(/#{public}/um)
          if @source.match?(/#{public}(?:\s+[^'"]|\s*[\[>])/um)
            return "public ID literal is missing"
          end
          unless @source.match?(/#{public}\s+#{PUBIDLITERAL}/um)
            return "invalid public ID literal"
          end
          if accept_public_id
            if @source.match?(/#{public}\s+#{PUBIDLITERAL}\s+[^'"]/um)
              return "system ID literal is missing"
            end
            unless @source.match?(/#{public}\s+#{PUBIDLITERAL}\s+#{SYSTEMLITERAL}/um)
              return "invalid system literal"
            end
            "garbage after system literal"
          else
            "garbage after public ID literal"
          end
        elsif accept_external_id and @source.match?(/#{system}/um)
          if @source.match?(/#{system}(?:\s+[^'"]|\s*[\[>])/um)
            return "system literal is missing"
          end
          unless @source.match?(/#{system}\s+#{SYSTEMLITERAL}/um)
            return "invalid system literal"
          end
          "garbage after system literal"
        else
          unless @source.match?(/\A\s*(?:PUBLIC|SYSTEM)\s/um)
            return "invalid ID type"
          end
          "ID type is missing"
        end
      end

      def process_comment
        text = @source.read_until("-->")
        unless text.chomp!("-->")
          raise REXML::ParseException.new("Unclosed comment: Missing end '-->'", @source)
        end

        if text.include? "--" or text.end_with?("-")
          raise REXML::ParseException.new("Malformed comment", @source)
        end
        text
      end

      def process_instruction
        name = parse_name("Malformed XML: Invalid processing instruction node")
        if name == "xml"
          xml_declaration
        else # PITarget
          if @source.skip_spaces # e.g. <?name content?>
            start_position = @source.position
            content = @source.read_until("?>")
            unless content.chomp!("?>")
              @source.position = start_position
              raise ParseException.new("Malformed XML: Unclosed processing instruction: <#{name}>", @source)
            end
          else # e.g. <?name?>
            content = nil
            unless @source.match?("?>", true)
              raise ParseException.new("Malformed XML: Unclosed processing instruction: <#{name}>", @source)
            end
          end
          [:processing_instruction, name, content]
        end
      end

      def xml_declaration
        unless @version.nil?
          raise ParseException.new("Malformed XML: XML declaration is duplicated", @source)
        end
        if @document_status
          raise ParseException.new("Malformed XML: XML declaration is not at the start", @source)
        end
        unless @source.skip_spaces
          raise ParseException.new("Malformed XML: XML declaration misses spaces before version", @source)
        end
        unless @source.match?("version", true)
          raise ParseException.new("Malformed XML: XML declaration misses version", @source)
        end
        @version = parse_attribute_value_with_equal("xml")
        unless @source.skip_spaces
          unless @source.match?("?>", true)
            raise ParseException.new("Malformed XML: Unclosed XML declaration", @source)
          end
          encoding = normalize_xml_declaration_encoding(@source.encoding)
          return [ :xmldecl, @version, encoding, nil ] # e.g. <?xml version="1.0"?>
        end

        if @source.match?("encoding", true)
          encoding = parse_attribute_value_with_equal("xml")
          unless @source.skip_spaces
            unless @source.match?("?>", true)
              raise ParseException.new("Malformed XML: Unclosed XML declaration", @source)
            end
            if need_source_encoding_update?(encoding)
              @source.encoding = encoding
            end
            encoding ||= normalize_xml_declaration_encoding(@source.encoding)
            return [ :xmldecl, @version, encoding, nil ] # e.g. <?xml version="1.1" encoding="UTF-8"?>
          end
        end

        if @source.match?("standalone", true)
          standalone = parse_attribute_value_with_equal("xml")
          case standalone
          when "yes", "no"
          else
            raise ParseException.new("Malformed XML: XML declaration standalone is not yes or no : <#{standalone}>", @source)
          end
        end
        @source.skip_spaces
        unless @source.match?("?>", true)
          raise ParseException.new("Malformed XML: Unclosed XML declaration", @source)
        end

        if need_source_encoding_update?(encoding)
          @source.encoding = encoding
        end
        encoding ||= normalize_xml_declaration_encoding(@source.encoding)

        # e.g. <?xml version="1.0" ?>
        #      <?xml version="1.1" encoding="UTF-8" ?>
        #      <?xml version="1.1" standalone="yes"?>
        #      <?xml version="1.1" encoding="UTF-8" standalone="yes" ?>
        [ :xmldecl, @version, encoding, standalone ]
      end

      if StringScanner::Version < "3.1.1"
        def scan_quote
          @source.match(/(['"])/, true)&.[](1)
        end
      else
        def scan_quote
          case @source.peek_byte
          when 34 # '"'.ord
            @source.scan_byte
            '"'
          when 39 # "'".ord
            @source.scan_byte
            "'"
          else
            nil
          end
        end
      end

      def parse_attribute_value_with_equal(name)
        unless @source.match?(Private::EQUAL_PATTERN, true)
          message = "Missing attribute equal: <#{name}>"
          raise REXML::ParseException.new(message, @source)
        end
        unless quote = scan_quote
          message = "Missing attribute value start quote: <#{name}>"
          raise REXML::ParseException.new(message, @source)
        end
        start_position = @source.position
        value = @source.read_until(quote)
        unless value.chomp!(quote)
          @source.position = start_position
          message = "Missing attribute value end quote: <#{name}>: <#{quote}>"
          raise REXML::ParseException.new(message, @source)
        end
        value
      end

      def parse_attributes(prefixes)
        attributes = {}
        expanded_names = {}
        closed = false
        while true
          if @source.match?(">", true)
            return attributes, closed
          elsif @source.match?("/>", true)
            closed = true
            return attributes, closed
          elsif match = @source.match(QNAME, true)
            name = match[1]
            prefix = match[2]
            local_part = match[3]
            value = parse_attribute_value_with_equal(name)
            @source.skip_spaces
            if prefix == "xmlns"
              if local_part == "xml"
                if value != Private::XML_PREFIXED_NAMESPACE
                  msg = "The 'xml' prefix must not be bound to any other namespace "+
                    "(http://www.w3.org/TR/REC-xml-names/#ns-decl)"
                  raise REXML::ParseException.new( msg, @source, self )
                end
              elsif local_part == "xmlns"
                msg = "The 'xmlns' prefix must not be declared "+
                  "(http://www.w3.org/TR/REC-xml-names/#ns-decl)"
                raise REXML::ParseException.new( msg, @source, self)
              end
              add_namespace(local_part, value)
            elsif prefix
              prefixes << prefix unless prefix == "xml"
            end

            if attributes[name]
              msg = "Duplicate attribute #{name.inspect}"
              raise REXML::ParseException.new(msg, @source, self)
            end

            unless prefix == "xmlns"
              uri = @namespaces[prefix]
              expanded_name = [uri, local_part]
              existing_prefix = expanded_names[expanded_name]
              if existing_prefix
                message = "Namespace conflict in adding attribute " +
                          "\"#{local_part}\": " +
                          "Prefix \"#{existing_prefix}\" = \"#{uri}\" and " +
                          "prefix \"#{prefix}\" = \"#{uri}\""
                raise REXML::ParseException.new(message, @source, self)
              end
              expanded_names[expanded_name] = prefix
            end

            attributes[name] = value
          else
            message = "Invalid attribute name: <#{@source.buffer.split(%r{[/>\s]}).first}>"
            raise REXML::ParseException.new(message, @source)
          end
        end
      end
    end
  end
end

=begin
  case event[0]
  when :start_element
  when :text
  when :end_element
  when :processing_instruction
  when :cdata
  when :comment
  when :xmldecl
  when :start_doctype
  when :end_doctype
  when :externalentity
  when :elementdecl
  when :entity
  when :attlistdecl
  when :notationdecl
  when :end_doctype
  end
=end
