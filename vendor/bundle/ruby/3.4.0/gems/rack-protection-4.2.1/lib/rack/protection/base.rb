# frozen_string_literal: true

require 'rack/protection'
require 'rack/utils'
require 'digest'
require 'logger'
require 'uri'

module Rack
  module Protection
    class Base
      DEFAULT_OPTIONS = {
        reaction: :default_reaction, logging: true,
        message: 'Forbidden', encryptor: Digest::SHA1,
        session_key: 'rack.session', status: 403,
        allow_empty_referrer: true,
        report_key: 'protection.failed',
        html_types: %w[text/html application/xhtml text/xml application/xml]
      }

      attr_reader :app, :options

      def self.default_options(options)
        define_method(:default_options) { super().merge(options) }
      end

      def self.default_reaction(reaction)
        alias_method(:default_reaction, reaction)
      end

      def default_options
        DEFAULT_OPTIONS
      end

      def initialize(app, options = {})
        @app = app
        @options = default_options.merge(options)
      end

      def safe?(env)
        %w[GET HEAD OPTIONS TRACE].include? env['REQUEST_METHOD']
      end

      def accepts?(env)
        raise NotImplementedError, "#{self.class} implementation pending"
      end

      def call(env)
        unless accepts? env
          instrument env
          result = react env
        end
        result or app.call(env)
      end

      def react(env)
        result = send(options[:reaction], env)
        result if (Array === result) && (result.size == 3)
      end

      def debug(env, message)
        return unless options[:logging]

        l = options[:logger] || env['rack.logger'] || ::Logger.new(env['rack.errors'])
        l.debug(message)
      end

      def warn(env, message)
        return unless options[:logging]

        l = options[:logger] || env['rack.logger'] || ::Logger.new(env['rack.errors'])
        l.warn(message)
      end

      def instrument(env)
        return unless (i = options[:instrumenter])

        env['rack.protection.attack'] = self.class.name.split('::').last.downcase
        i.instrument('rack.protection', env)
      end

      def deny(env)
        warn env, "attack prevented by #{self.class}"
        [options[:status], { 'content-type' => 'text/plain' }, [options[:message]]]
      end

      def report(env)
        warn env, "attack reported by #{self.class}"
        env[options[:report_key]] = true
      end

      def session?(env)
        env.include? options[:session_key]
      end

      def session(env)
        return env[options[:session_key]] if session? env

        raise "you need to set up a session middleware *before* #{self.class}"
      end

      def drop_session(env)
        return unless session? env

        session(env).clear

        return if ["1", "true"].include?(ENV["RACK_PROTECTION_SILENCE_DROP_SESSION_WARNING"])

        warn env, "session dropped by #{self.class}"
      end

      def referrer(env)
        ref = env['HTTP_REFERER'].to_s
        return if !options[:allow_empty_referrer] && ref.empty?

        URI.parse(ref).host || Request.new(env).host
      rescue URI::InvalidURIError
      end

      def origin(env)
        env['HTTP_ORIGIN'] || env['HTTP_X_ORIGIN']
      end

      def random_string(secure = defined? SecureRandom)
        secure ? SecureRandom.hex(16) : '%032x' % rand((2**128) - 1)
      rescue NotImplementedError
        random_string false
      end

      def encrypt(value)
        options[:encryptor].hexdigest value.to_s
      end

      def secure_compare(a, b)
        Rack::Utils.secure_compare(a.to_s, b.to_s)
      end

      alias default_reaction deny

      def html?(headers)
        return false unless (header = headers.detect { |k, _v| k.downcase == 'content-type' })

        options[:html_types].include? header.last[%r{^\w+/\w+}]
      end
    end
  end
end
