# frozen_string_literal: true

require 'forwardable'

module Rack
  module Test
    # This module serves as the primary integration point for using Rack::Test
    # in a testing environment. It depends on an app method being defined in the
    # same context, and provides the Rack::Test API methods (see Rack::Test::Session
    # for their documentation). It defines the following methods that are delegated
    # to the current session: :request, :get, :post, :put, :patch, :delete, :options,
    # :head, :custom_request, :follow_redirect!, :header, :env, :set_cookie,
    # :clear_cookies, :authorize, :basic_authorize, :last_response, and :last_request.
    #
    # Example:
    #
    #   class HomepageTest < Test::Unit::TestCase
    #     include Rack::Test::Methods
    #
    #     def app
    #       MyApp
    #     end
    #   end
    module Methods
      extend Forwardable

      # Return the existing session with the given name, or a new
      # rack session.  Always use a new session if name is nil.
      def rack_test_session(name = :default) # :nodoc:
        return build_rack_test_session(name) unless name

        @_rack_test_sessions ||= {}
        @_rack_test_sessions[name] ||= build_rack_test_session(name)
      end

      # For backwards compatibility with older rack-test versions.
      alias rack_mock_session rack_test_session # :nodoc:

      # Create a new Rack::Test::Session for #app.
      def build_rack_test_session(_name) # :nodoc:
        if respond_to?(:build_rack_mock_session, true)
          # Backwards compatibility for capybara
          build_rack_mock_session
        else
          if respond_to?(:default_host)
            Session.new(app, default_host)
          else
            Session.new(app)
          end
        end
      end

      # Return the currently actively session.  This is the session to
      # which the delegated methods are sent.
      def current_session
        @_rack_test_current_session ||= rack_test_session
      end

      # Create a new session (or reuse an existing session with the given name),
      # and make it the current session for the given block.
      def with_session(name)
        session = _rack_test_current_session
        yield(@_rack_test_current_session = rack_test_session(name))
      ensure
        @_rack_test_current_session = session
      end

      def_delegators(:current_session,
        :request,
        :get,
        :post,
        :put,
        :patch,
        :delete,
        :options,
        :head,
        :custom_request,
        :follow_redirect!,
        :header,
        :env,
        :set_cookie,
        :clear_cookies,
        :authorize,
        :basic_authorize,
        :last_response,
        :last_request,
      )

      # Private accessor to avoid uninitialized instance variable warning in Ruby 2.*
      attr_accessor :_rack_test_current_session
      private :_rack_test_current_session
    end
  end
end
