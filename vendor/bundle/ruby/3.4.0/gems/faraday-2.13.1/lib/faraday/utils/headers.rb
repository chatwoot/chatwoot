# frozen_string_literal: true

module Faraday
  module Utils
    # A case-insensitive Hash that preserves the original case of a header
    # when set.
    #
    # Adapted from Rack::Utils::HeaderHash
    class Headers < ::Hash
      def self.from(value)
        new(value)
      end

      def self.allocate
        new_self = super
        new_self.initialize_names
        new_self
      end

      def initialize(hash = nil)
        super()
        @names = {}
        update(hash || {})
      end

      def initialize_names
        @names = {}
      end

      # on dup/clone, we need to duplicate @names hash
      def initialize_copy(other)
        super
        @names = other.names.dup
      end

      # need to synchronize concurrent writes to the shared KeyMap
      keymap_mutex = Mutex.new

      # symbol -> string mapper + cache
      KeyMap = Hash.new do |map, key|
        value = if key.respond_to?(:to_str)
                  key
                else
                  key.to_s.split('_') # user_agent: %w(user agent)
                     .each(&:capitalize!) # => %w(User Agent)
                     .join('-') # => "User-Agent"
                end
        keymap_mutex.synchronize { map[key] = value }
      end
      KeyMap[:etag] = 'ETag'

      def [](key)
        key = KeyMap[key]
        super(key) || super(@names[key.downcase])
      end

      def []=(key, val)
        key = KeyMap[key]
        key = (@names[key.downcase] ||= key)
        # join multiple values with a comma
        val = val.to_ary.join(', ') if val.respond_to?(:to_ary)
        super(key, val)
      end

      def fetch(key, ...)
        key = KeyMap[key]
        key = @names.fetch(key.downcase, key)
        super(key, ...)
      end

      def delete(key)
        key = KeyMap[key]
        key = @names[key.downcase]
        return unless key

        @names.delete key.downcase
        super(key)
      end

      def dig(key, *rest)
        key = KeyMap[key]
        key = @names.fetch(key.downcase, key)
        super(key, *rest)
      end

      def include?(key)
        @names.include? key.downcase
      end

      alias has_key? include?
      alias member? include?
      alias key? include?

      def merge!(other)
        other.each { |k, v| self[k] = v }
        self
      end

      alias update merge!

      def merge(other)
        hash = dup
        hash.merge! other
      end

      def replace(other)
        clear
        @names.clear
        update other
        self
      end

      def to_hash
        {}.update(self)
      end

      def parse(header_string)
        return unless header_string && !header_string.empty?

        headers = header_string.split("\r\n")

        # Find the last set of response headers.
        start_index = headers.rindex { |x| x.start_with?('HTTP/') } || 0
        last_response = headers.slice(start_index, headers.size)

        last_response
          .tap { |a| a.shift if a.first.start_with?('HTTP/') }
          .map { |h| h.split(/:\s*/, 2) } # split key and value
          .reject { |p| p[0].nil? } # ignore blank lines
          .each { |key, value| add_parsed(key, value) }
      end

      protected

      attr_reader :names

      private

      # Join multiple values with a comma.
      def add_parsed(key, value)
        if key?(key)
          self[key] = self[key].to_s
          self[key] << ', ' << value
        else
          self[key] = value
        end
      end
    end
  end
end
