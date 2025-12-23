# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2023, by Samuel Williams.

require_relative 'abstract/id'

module Rack
  module Session
    # Rack::Session::Pool provides simple cookie based session management.
    # Session data is stored in a hash held by @pool.
    # In the context of a multithreaded environment, sessions being
    # committed to the pool is done in a merging manner.
    #
    # The :drop option is available in rack.session.options if you wish to
    # explicitly remove the session from the session cache.
    #
    # Example:
    #   myapp = MyRackApp.new
    #   sessioned = Rack::Session::Pool.new(myapp,
    #     :domain => 'foo.com',
    #     :expire_after => 2592000
    #   )
    #   Rack::Handler::WEBrick.run sessioned

    class Pool < Abstract::PersistedSecure
      attr_reader :mutex, :pool
      DEFAULT_OPTIONS = Abstract::ID::DEFAULT_OPTIONS.merge(drop: false, allow_fallback: true)

      def initialize(app, options = {})
        super
        @pool = Hash.new
        @mutex = Mutex.new
        @allow_fallback = @default_options.delete(:allow_fallback)
      end

      def generate_sid(*args, use_mutex: true)
        loop do
          sid = super(*args)
          break sid unless use_mutex ? @mutex.synchronize { @pool.key? sid.private_id } : @pool.key?(sid.private_id)
        end
      end

      def find_session(req, sid)
        @mutex.synchronize do
          unless sid and session = get_session_with_fallback(sid)
            sid, session = generate_sid(use_mutex: false), {}
            @pool.store sid.private_id, session
          end
          [sid, session]
        end
      end

      def write_session(req, session_id, new_session, options)
        @mutex.synchronize do
          return false unless get_session_with_fallback(session_id)
          @pool.store session_id.private_id, new_session
          session_id
        end
      end

      def delete_session(req, session_id, options)
        @mutex.synchronize do
          @pool.delete(session_id.public_id)
          @pool.delete(session_id.private_id)

          unless options[:drop]
            sid = generate_sid(use_mutex: false)
            @pool.store(sid.private_id, {})
            sid
          end
        end
      end

      private

      def get_session_with_fallback(sid)
        @pool[sid.private_id] || (@pool[sid.public_id] if @allow_fallback)
      end
    end
  end
end
