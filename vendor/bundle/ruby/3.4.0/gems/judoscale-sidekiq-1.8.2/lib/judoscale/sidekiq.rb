# frozen_string_literal: true

require "judoscale-ruby"
require "judoscale/config"
require "judoscale/version"
require "judoscale/sidekiq/metrics_collector"
require "sidekiq/api"

Judoscale.add_adapter :"judoscale-sidekiq",
  {
    adapter_version: Judoscale::VERSION,
    framework_version: ::Sidekiq::VERSION
  },
  metrics_collector: Judoscale::Sidekiq::MetricsCollector,
  expose_config: Judoscale::Config::JobAdapterConfig.new(:sidekiq)
