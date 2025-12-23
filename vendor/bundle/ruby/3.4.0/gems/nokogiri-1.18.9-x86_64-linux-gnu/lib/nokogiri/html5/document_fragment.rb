# coding: utf-8
# frozen_string_literal: true

#
#  Copyright 2013-2021 Sam Ruby, Stephen Checkoway
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

require_relative "../html4/document_fragment"

module Nokogiri
  module HTML5
    # Since v1.12.0
    #
    # 💡 HTML5 functionality is not available when running JRuby.
    class DocumentFragment < Nokogiri::HTML4::DocumentFragment
      class << self
        # :call-seq:
        #   parse(input, **options) → HTML5::DocumentFragment
        #
        # Parse \HTML5 fragment input from a String, and return a new HTML5::DocumentFragment. This
        # method creates a new, empty HTML5::Document to contain the fragment.
        #
        # [Parameters]
        # - +input+ (String | IO) The HTML5 document fragment to parse.
        #
        # [Optional Keyword Arguments]
        # - +encoding:+ (String | Encoding) The encoding, or name of the encoding, that should be
        #   used when processing the document. When not provided, the encoding will be determined
        #   based on the document content. Also see Nokogiri::HTML5 for a longer explanation of how
        #   encoding is handled by the parser.
        #
        # - +context:+ (String | Nokogiri::XML::Node) The node, or the name of an HTML5 element, "in
        #   context" of which to parse the document fragment. See below for more
        #   information. (default +"body"+)
        #
        # - +max_errors:+ (Integer) The maximum number of parse errors to record. (default
        #   +Nokogiri::Gumbo::DEFAULT_MAX_ERRORS+ which is currently 0)
        #
        # - +max_tree_depth:+ (Integer) The maximum depth of the parse tree. (default
        #   +Nokogiri::Gumbo::DEFAULT_MAX_TREE_DEPTH+)
        #
        # - +max_attributes:+ (Integer) The maximum number of attributes allowed on an
        #   element. (default +Nokogiri::Gumbo::DEFAULT_MAX_ATTRIBUTES+)
        #
        # - +parse_noscript_content_as_text:+ (Boolean) Whether to parse the content of +noscript+
        #   elements as text. (default +false+)
        #
        # See rdoc-ref:HTML5@Parsing+options for a complete description of these parsing options.
        #
        # [Returns] Nokogiri::HTML5::DocumentFragment
        #
        # === Context \Node
        #
        # If a context node is specified using +context:+, then the parser will behave as if that
        # Node, or a hypothetical tag named as specified, is the parent of the fragment subtree.
        #
        def parse(
          input,
          encoding_ = nil, positional_options_hash = nil,
          encoding: encoding_, **options
        )
          unless positional_options_hash.nil? || positional_options_hash.empty?
            options.merge!(positional_options_hash)
          end

          context = options.delete(:context)

          document = HTML5::Document.new
          document.encoding = "UTF-8"
          input = HTML5.read_and_encode(input, encoding)

          new(document, input, context, options)
        end
      end

      attr_accessor :document
      attr_accessor :errors

      # Get the parser's quirks mode value. See HTML5::QuirksMode.
      #
      # This method returns `nil` if the parser was not invoked (e.g.,
      # `Nokogiri::HTML5::DocumentFragment.new(doc)`).
      #
      # Since v1.14.0
      attr_reader :quirks_mode

      #
      # :call-seq:
      #   new(document, input, **options) → HTML5::DocumentFragment
      #
      # Parse \HTML5 fragment input from a String, and return a new HTML5::DocumentFragment.
      #
      # 💡 It's recommended to use either HTML5::DocumentFragment.parse or HTML5::Node#fragment
      # rather than call this method directly.
      #
      # [Required Parameters]
      # - +document+ (HTML5::Document) The parent document to associate the returned fragment with.
      #
      # [Optional Parameters]
      # - +input+ (String) The content to be parsed.
      #
      # [Optional Keyword Arguments]
      # - +encoding:+ (String | Encoding) The encoding, or name of the encoding, that should be
      #   used when processing the document. When not provided, the encoding will be determined
      #   based on the document content. Also see Nokogiri::HTML5 for a longer explanation of how
      #   encoding is handled by the parser.
      #
      # - +context:+ (String | Nokogiri::XML::Node) The node, or the name of an HTML5 element, in
      #   which to parse the document fragment. (default +"body"+)
      #
      # - +max_errors:+ (Integer) The maximum number of parse errors to record. (default
      #   +Nokogiri::Gumbo::DEFAULT_MAX_ERRORS+ which is currently 0)
      #
      # - +max_tree_depth:+ (Integer) The maximum depth of the parse tree. (default
      #   +Nokogiri::Gumbo::DEFAULT_MAX_TREE_DEPTH+)
      #
      # - +max_attributes:+ (Integer) The maximum number of attributes allowed on an
      #   element. (default +Nokogiri::Gumbo::DEFAULT_MAX_ATTRIBUTES+)
      #
      # - +parse_noscript_content_as_text:+ (Boolean) Whether to parse the content of +noscript+
      #   elements as text. (default +false+)
      #
      # See rdoc-ref:HTML5@Parsing+options for a complete description of these parsing options.
      #
      # [Returns] HTML5::DocumentFragment
      #
      # === Context \Node
      #
      # If a context node is specified using +context:+, then the parser will behave as if that
      # Node, or a hypothetical tag named as specified, is the parent of the fragment subtree.
      #
      def initialize(
        doc, input = nil,
        context_ = nil, positional_options_hash = nil,
        context: context_,
        **options
      ) # rubocop:disable Lint/MissingSuper
        unless positional_options_hash.nil? || positional_options_hash.empty?
          options.merge!(positional_options_hash)
        end

        @document = doc
        @errors = []
        return self unless input

        input = Nokogiri::HTML5.read_and_encode(input, nil)

        context = options.delete(:context) if options.key?(:context)

        options[:max_attributes] ||= Nokogiri::Gumbo::DEFAULT_MAX_ATTRIBUTES
        options[:max_errors] ||= options.delete(:max_parse_errors) || Nokogiri::Gumbo::DEFAULT_MAX_ERRORS
        options[:max_tree_depth] ||= Nokogiri::Gumbo::DEFAULT_MAX_TREE_DEPTH

        Nokogiri::Gumbo.fragment(self, input, context, **options)
      end

      def serialize(options = {}, &block) # :nodoc:
        # Bypass XML::Document.serialize which doesn't support options even
        # though XML::Node.serialize does!
        XML::Node.instance_method(:serialize).bind_call(self, options, &block)
      end

      def extract_params(params) # :nodoc:
        handler = params.find do |param|
          ![Hash, String, Symbol].include?(param.class)
        end
        params -= [handler] if handler

        hashes = []
        while Hash === params.last || params.last.nil?
          hashes << params.pop
          break if params.empty?
        end
        ns, binds = hashes.reverse

        ns ||=
          begin
            ns = {}
            children.each { |child| ns.merge!(child.namespaces) }
            ns
          end

        [params, handler, ns, binds]
      end
    end
  end
end
# vim: set shiftwidth=2 softtabstop=2 tabstop=8 expandtab:
