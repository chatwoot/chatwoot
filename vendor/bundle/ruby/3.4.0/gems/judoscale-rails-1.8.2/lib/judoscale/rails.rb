# frozen_string_literal: true

require "judoscale-ruby"
require "judoscale/version"
require "judoscale/rails/railtie"
require "judoscale/web_metrics_collector"
require "rails/version"

Judoscale.add_adapter :"judoscale-rails", {
  adapter_version: Judoscale::VERSION,
  framework_version: ::Rails.version
}, metrics_collector: Judoscale::WebMetricsCollector
