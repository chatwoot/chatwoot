# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2011-2018, by Tony Arcieri.
# Copyright, 2015, by Upekshe Jayasekera.
# Copyright, 2015, by Vladimir Kochnev.
# Copyright, 2018-2023, by Samuel Williams.
# Copyright, 2019-2020, by Gregory Longtin.

module NIO
  # Monitors watch IO objects for specific events
  class Monitor
    attr_reader :io, :interests, :selector
    attr_accessor :value, :readiness

    # :nodoc:
    def initialize(io, interests, selector)
      unless defined?(::OpenSSL) && io.is_a?(::OpenSSL::SSL::SSLSocket)
        unless io.is_a?(IO)
          if IO.respond_to? :try_convert
            io = IO.try_convert(io)
          elsif io.respond_to? :to_io
            io = io.to_io
          end

          raise TypeError, "can't convert #{io.class} into IO" unless io.is_a? IO
        end
      end

      @io        = io
      @interests = interests
      @selector  = selector
      @closed    = false
    end

    # Replace the existing interest set with a new one
    #
    # @param interests [:r, :w, :rw, nil] I/O readiness we're interested in (read/write/readwrite)
    #
    # @return [Symbol] new interests
    def interests=(interests)
      raise EOFError, "monitor is closed" if closed?
      raise ArgumentError, "bad interests: #{interests}" unless [:r, :w, :rw, nil].include?(interests)

      @interests = interests
    end

    # Add new interests to the existing interest set
    #
    # @param interests [:r, :w, :rw] new I/O interests (read/write/readwrite)
    #
    # @return [self]
    def add_interest(interest)
      case interest
      when :r
        case @interests
        when :r  then @interests = :r
        when :w  then @interests = :rw
        when :rw then @interests = :rw
        when nil then @interests = :r
        end
      when :w
        case @interests
        when :r  then @interests = :rw
        when :w  then @interests = :w
        when :rw then @interests = :rw
        when nil then @interests = :w
        end
      when :rw
        @interests = :rw
      else raise ArgumentError, "bad interests: #{interest}"
      end
    end

    # Remove interests from the existing interest set
    #
    # @param interests [:r, :w, :rw] I/O interests to remove (read/write/readwrite)
    #
    # @return [self]
    def remove_interest(interest)
      case interest
      when :r
        case @interests
        when :r  then @interests = nil
        when :w  then @interests = :w
        when :rw then @interests = :w
        when nil then @interests = nil
        end
      when :w
        case @interests
        when :r  then @interests = :r
        when :w  then @interests = nil
        when :rw then @interests = :r
        when nil then @interests = nil
        end
      when :rw
        @interests = nil
      else raise ArgumentError, "bad interests: #{interest}"
      end
    end

    # Is the IO object readable?
    def readable?
      readiness == :r || readiness == :rw
    end

    # Is the IO object writable?
    def writable?
      readiness == :w || readiness == :rw
    end
    alias writeable? writable?

    # Is this monitor closed?
    def closed?
      @closed
    end

    # Deactivate this monitor
    def close(deregister = true)
      @closed = true
      @selector.deregister(io) if deregister
    end
  end
end
