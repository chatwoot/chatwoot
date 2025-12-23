# frozen_string_literal: true

require 'uri/common'

module Puma
  module Util
    module_function

    def pipe
      IO.pipe
    end

    # An instance method on Thread has been provided to address https://bugs.ruby-lang.org/issues/13632,
    # which currently effects some older versions of Ruby: 2.2.7 2.2.8 2.2.9 2.2.10 2.3.4 2.4.1
    # Additional context: https://github.com/puma/puma/pull/1345
    def purge_interrupt_queue
      Thread.current.purge_interrupt_queue if Thread.current.respond_to? :purge_interrupt_queue
    end

    # Escapes and unescapes a URI escaped string with
    # +encoding+. +encoding+ will be the target encoding of the string
    # returned, and it defaults to UTF-8
    if defined?(::Encoding)
      def escape(s, encoding = Encoding::UTF_8)
        URI.encode_www_form_component(s, encoding)
      end

      def unescape(s, encoding = Encoding::UTF_8)
        URI.decode_www_form_component(s, encoding)
      end
    else
      def escape(s, encoding = nil)
        URI.encode_www_form_component(s, encoding)
      end

      def unescape(s, encoding = nil)
        URI.decode_www_form_component(s, encoding)
      end
    end
    module_function :unescape, :escape

    DEFAULT_SEP = /[&;] */n

    # Stolen from Mongrel, with some small modifications:
    # Parses a query string by breaking it up at the '&'
    # and ';' characters.  You can also use this to parse
    # cookies by changing the characters used in the second
    # parameter (which defaults to '&;').
    def parse_query(qs, d = nil, &unescaper)
      unescaper ||= method(:unescape)

      params = {}

      (qs || '').split(d ? /[#{d}] */n : DEFAULT_SEP).each do |p|
        next if p.empty?
        k, v = p.split('=', 2).map(&unescaper)

        if cur = params[k]
          if cur.class == Array
            params[k] << v
          else
            params[k] = [cur, v]
          end
        else
          params[k] = v
        end
      end

      params
    end

    # A case-insensitive Hash that preserves the original case of a
    # header when set.
    class HeaderHash < Hash
      def self.new(hash={})
        HeaderHash === hash ? hash : super(hash)
      end

      def initialize(hash={})
        super()
        @names = {}
        hash.each { |k, v| self[k] = v }
      end

      def each
        super do |k, v|
          yield(k, v.respond_to?(:to_ary) ? v.to_ary.join("\n") : v)
        end
      end

      # @!attribute [r] to_hash
      def to_hash
        hash = {}
        each { |k,v| hash[k] = v }
        hash
      end

      def [](k)
        super(k) || super(@names[k.downcase])
      end

      def []=(k, v)
        canonical = k.downcase
        delete k if @names[canonical] && @names[canonical] != k # .delete is expensive, don't invoke it unless necessary
        @names[k] = @names[canonical] = k
        super k, v
      end

      def delete(k)
        canonical = k.downcase
        result = super @names.delete(canonical)
        @names.delete_if { |name,| name.downcase == canonical }
        result
      end

      def include?(k)
        @names.include?(k) || @names.include?(k.downcase)
      end

      alias_method :has_key?, :include?
      alias_method :member?, :include?
      alias_method :key?, :include?

      def merge!(other)
        other.each { |k, v| self[k] = v }
        self
      end

      def merge(other)
        hash = dup
        hash.merge! other
      end

      def replace(other)
        clear
        other.each { |k, v| self[k] = v }
        self
      end
    end
  end
end
