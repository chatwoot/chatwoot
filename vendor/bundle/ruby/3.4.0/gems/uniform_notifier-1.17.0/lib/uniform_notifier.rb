# frozen_string_literal: true

require 'uniform_notifier/base'
require 'uniform_notifier/errors'
require 'uniform_notifier/javascript_alert'
require 'uniform_notifier/javascript_console'
require 'uniform_notifier/honeybadger'
require 'uniform_notifier/xmpp'
require 'uniform_notifier/rails_logger'
require 'uniform_notifier/customized_logger'
require 'uniform_notifier/airbrake'
require 'uniform_notifier/sentry'
require 'uniform_notifier/rollbar'
require 'uniform_notifier/bugsnag'
require 'uniform_notifier/appsignal'
require 'uniform_notifier/slack'
require 'uniform_notifier/raise'
require 'uniform_notifier/terminal_notifier'
require 'uniform_notifier/opentelemetry'

class UniformNotifier
  AVAILABLE_NOTIFIERS = %i[
    alert
    console
    honeybadger
    xmpp
    rails_logger
    customized_logger
    airbrake
    rollbar
    bugsnag
    slack
    raise
    sentry
    appsignal
    terminal_notifier
    opentelemetry
  ].freeze

  NOTIFIERS = [
    JavascriptAlert,
    JavascriptConsole,
    HoneybadgerNotifier,
    Xmpp,
    RailsLogger,
    CustomizedLogger,
    AirbrakeNotifier,
    RollbarNotifier,
    BugsnagNotifier,
    Raise,
    Slack,
    SentryNotifier,
    AppsignalNotifier,
    TerminalNotifier,
    OpenTelemetryNotifier
  ].freeze

  class NotificationError < StandardError
  end

  class << self
    attr_accessor(*AVAILABLE_NOTIFIERS)

    def active_notifiers
      NOTIFIERS.select(&:active?)
    end

    undef xmpp=
    def xmpp=(xmpp)
      UniformNotifier::Xmpp.setup_connection(xmpp)
    end

    undef customized_logger=
    def customized_logger=(logdev)
      UniformNotifier::CustomizedLogger.setup(logdev)
    end

    undef slack=
    def slack=(slack)
      UniformNotifier::Slack.setup_connection(slack)
    end

    undef raise=
    def raise=(exception_class)
      UniformNotifier::Raise.setup_connection(exception_class)
    end
  end
end
