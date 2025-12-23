# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'helpers/format'
include Format

namespace :newrelic do
  namespace :config do
    GENERAL = 'general'
    DISABLING = 'disabling'
    ATTRIBUTES = 'attributes'

    # these configuration options are not able to be set using environment variables
    NON_ENV_CONFIGS = ['error_collector.ignore_classes', 'error_collector.ignore_messages', 'error_collector.expected_classes', 'error_collector.expected_messages']

    SECTION_DESCRIPTIONS = {
      GENERAL => 'These settings are available for agent configuration. Some settings depend on your New Relic subscription level.',
      DISABLING => 'Use these settings to toggle instrumentation types during agent startup.',
      ATTRIBUTES => '[Attributes](/docs/features/agent-attributes) are key-value pairs containing information that determines the properties of an event or transaction. These key-value pairs can be viewed within transaction traces in APM, traced errors in APM, transaction events in dashboards, and page views in dashboards. You can customize exactly which attributes will be sent to each of these destinations',
      'transaction_tracer' => 'The [transaction traces](/docs/apm/traces/transaction-traces/transaction-traces) feature collects detailed information from a selection of transactions, including a summary of the calling sequence, a breakdown of time spent, and a list of SQL queries and their query plans (on mysql and postgresql). Available features depend on your New Relic subscription level.',
      'error_collector' => "The agent collects and reports all uncaught exceptions by default. These configuration options allow you to customize the error collection.\n\nFor information on ignored and expected errors, [see this page on Error Analytics in APM](/docs/agents/manage-apm-agents/agent-data/manage-errors-apm-collect-ignore-or-mark-expected/). To set expected errors via the `NewRelic::Agent.notice_error` Ruby method, [consult the Ruby Agent API](/docs/agents/ruby-agent/api-guides/sending-handled-errors-new-relic/).",
      'browser_monitoring' => "The browser monitoring [page load timing](/docs/browser/new-relic-browser/page-load-timing/page-load-timing-process) feature (sometimes referred to as real user monitoring or RUM) gives you insight into the performance real users are experiencing with your website. This is accomplished by measuring the time it takes for your users' browsers to download and render your web pages by injecting a small amount of JavaScript code into the header and footer of each page.",
      'application_logging' => "The Ruby agent supports [APM logs in context](/docs/apm/new-relic-apm/getting-started/get-started-logs-context). For some tips on configuring logs for the Ruby agent, see [Configure Ruby logs in context](/docs/logs/logs-context/configure-logs-context-ruby).\n\nAvailable logging-related config options include:",
      'analytics_events' => '[New Relic dashboards](/docs/query-your-data/explore-query-data/dashboards/introduction-new-relic-one-dashboards) is a resource to gather and visualize data about your software and what it says about your business. With it you can quickly and easily create real-time dashboards to get immediate answers about end-user experiences, clickstreams, mobile activities, and server transactions.'
    }

    NAME_OVERRIDES = {
      'slow_sql' => 'Slow SQL [#slow-sql]',
      'custom_insights_events' => 'Custom Events [#custom-events]'
    }

    desc 'Describe available New Relic configuration settings'
    task :docs, [:format] => [] do |t, args|
      require File.expand_path(File.join(File.dirname(__FILE__), '..', 'new_relic', 'agent', 'configuration', 'default_source.rb'))
      format = args[:format] || 'text'
      output(format)
    end
  end
end
