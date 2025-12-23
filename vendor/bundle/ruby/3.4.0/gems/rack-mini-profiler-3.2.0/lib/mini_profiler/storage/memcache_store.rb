# frozen_string_literal: true

module Rack
  class MiniProfiler
    class MemcacheStore < AbstractStore

      EXPIRES_IN_SECONDS = 60 * 60 * 24
      MAX_RETRIES        = 10

      def initialize(args = nil)
        require 'dalli' unless defined? Dalli
        args ||= {}

        @prefix = args[:prefix] || "MPMemcacheStore"
        @prefix += "-#{Rack::MiniProfiler::VERSION}"

        @client             = args[:client]     || Dalli::Client.new
        @expires_in_seconds = args[:expires_in] || EXPIRES_IN_SECONDS
      end

      def alive?
        begin
          @client.alive!
          true
        rescue Dalli::RingError
          false
        end
      end

      def save(page_struct)
        @client.set("#{@prefix}#{page_struct[:id]}", Marshal::dump(page_struct), @expires_in_seconds)
      end

      def load(id)
        raw = @client.get("#{@prefix}#{id}")
        # rubocop:disable Security/MarshalLoad
        Marshal.load(raw) if raw
        # rubocop:enable Security/MarshalLoad
      end

      def set_unviewed(user, id)
        @client.add("#{@prefix}-#{user}-v", [], @expires_in_seconds)
        MAX_RETRIES.times do
          break if @client.cas("#{@prefix}-#{user}-v", @expires_in_seconds) do |ids|
            ids << id unless ids.include?(id)
            ids
          end
        end
      end

      def set_viewed(user, id)
        @client.add("#{@prefix}-#{user}-v", [], @expires_in_seconds)
        MAX_RETRIES.times do
          break if @client.cas("#{@prefix}-#{user}-v", @expires_in_seconds) do |ids|
            ids.delete id
            ids
          end
        end
      end

      def set_all_unviewed(user, ids)
        @client.set("#{@prefix}-#{user}-v", ids, @expires_in_seconds)
      end

      def get_unviewed_ids(user)
        @client.get("#{@prefix}-#{user}-v") || []
      end

      def flush_tokens
        @client.set("#{@prefix}-tokens", nil)
      end

      def allowed_tokens

        token_info = @client.get("#{@prefix}-tokens")
        key1, key2, cycle_at = nil

        if token_info
          # rubocop:disable Security/MarshalLoad
          key1, key2, cycle_at = Marshal.load(token_info)
          # rubocop:enable Security/MarshalLoad

          key1 = nil unless key1 && key1.length == 32
          key2 = nil unless key2 && key2.length == 32

          if key1 && cycle_at && (cycle_at > Process.clock_gettime(Process::CLOCK_MONOTONIC))
            return [key1, key2].compact
          end
        end

        timeout = Rack::MiniProfiler::AbstractStore::MAX_TOKEN_AGE

        # cycle keys
        key2 = key1
        key1 = SecureRandom.hex
        cycle_at = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout

        @client.set("#{@prefix}-tokens", Marshal::dump([key1, key2, cycle_at]))

        [key1, key2].compact
      end

    end
  end
end
