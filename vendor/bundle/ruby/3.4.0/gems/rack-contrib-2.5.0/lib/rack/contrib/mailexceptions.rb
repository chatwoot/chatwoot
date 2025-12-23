# frozen_string_literal: true

require 'net/smtp'
require 'mail'
require 'erb'

module Rack
  # Catches all exceptions raised from the app it wraps and
  # sends a useful email with the exception, stacktrace, and
  # contents of the environment.

  # use smtp
  #    use Rack::MailExceptions do |mail|
  #      mail.to 'test@gmail.com'
  #      mail.smtp :address => 'mail.test.com', :user_name => 'test@test.com', :password => 'test'
  #    end
  # use sendmail
  #    use Rack::MailExceptions do |mail|
  #      mail.to 'test@gmail.com'
  #      mail.smtp false
  #    end

  class MailExceptions
    attr_reader :config

    def initialize(app)
      @app = app
      @config = {
        :to      => nil,
        :from    => ENV['USER'] || 'rack@localhost',
        :subject => '[exception] %s',
        :smtp    => {
          :address        => 'localhost',
          :domain         => 'localhost',
          :port           => 25,
          :authentication => :login,
          :user_name      => nil,
          :password       => nil
        }
      }
      @template = ERB.new(TEMPLATE)
      @test_mode = false
      yield self if block_given?
    end

    def call(env)
      status, headers, body =
        begin
          @app.call(env)
        rescue => boom
          send_notification boom, env
          raise
        end
      send_notification env['mail.exception'], env if env['mail.exception']
      [status, headers, body]
    end

    %w[to from subject].each do |meth|
      define_method(meth) { |value| @config[meth.to_sym] = value }
    end

    def smtp(settings={})
      if settings
        @config[:smtp].merge! settings
      else
        @config[:smtp] = nil
      end
    end

    def enable_test_mode
      @test_mode = true
    end

    def disable_test_mode
      @test_mode = false
    end

  private
    def generate_mail(exception, env)
      Mail.new({
        :from => config[:from],
        :to => config[:to],
        :subject => config[:subject] % [exception.to_s],
        :body => @template.result(binding),
        :charset => "UTF-8"
      })
    end

    def send_notification(exception, env)
      mail = generate_mail(exception, env)
      if @test_mode
        mail.delivery_method :test
      elsif config[:smtp]
        smtp = config[:smtp]
        # for backward compatibility, replace the :server key with :address
        address = smtp.delete :server
        smtp[:address] = address if address
        mail.delivery_method :smtp, smtp
      else
        mail.delivery_method :sendmail
      end
      mail.deliver!
      env['mail.sent'] = true
      mail
    end

    def extract_body(env)
      if io = env['rack.input']
        io.rewind if io.respond_to?(:rewind)
        io.read
      end
    end

    TEMPLATE = (<<-'EMAIL').gsub(/^ {4}/, '')
    A <%= exception.class.to_s %> occured: <%= exception.to_s %>
    <% if body = extract_body(env) %>

    ===================================================================
    Request Body:
    ===================================================================

    <%= body.gsub(/^/, '  ') %>
    <% end %>

    ===================================================================
    Rack Environment:
    ===================================================================

      PID:                     <%= $$ %>
      PWD:                     <%= Dir.getwd %>

      <%= env.to_a.
        sort{|a,b| a.first <=> b.first}.
        map do |k,v|
          if k == 'HTTP_AUTHORIZATION' and v =~ /^Basic /
            v = 'Basic *filtered*'
         end
          "%-25s%p" % [k+':', v]
        end.
        join("\n  ") %>

    <% if exception.respond_to?(:backtrace) %>
    ===================================================================
    Backtrace:
    ===================================================================

      <%= exception.backtrace.join("\n  ") %>
    <% end %>
    EMAIL

  end
end
