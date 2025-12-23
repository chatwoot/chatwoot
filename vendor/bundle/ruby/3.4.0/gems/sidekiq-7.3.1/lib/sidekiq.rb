# frozen_string_literal: true

require "sidekiq/version"
fail "Sidekiq #{Sidekiq::VERSION} does not support Ruby versions below 2.7.0." if RUBY_PLATFORM != "java" && Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.7.0")

begin
  require "sidekiq-ent/version"
  fail <<~EOM  if Gem::Version.new(Sidekiq::Enterprise::VERSION).segments[0] != Sidekiq::MAJOR

    Sidekiq Enterprise #{Sidekiq::Enterprise::VERSION} does not work with Sidekiq #{Sidekiq::VERSION}.
    Starting with Sidekiq 7, major versions are synchronized so Sidekiq Enterprise 7 works with Sidekiq 7.
    Use `bundle up sidekiq-ent` to upgrade.

  EOM
rescue LoadError
end

begin
  require "sidekiq/pro/version"
  fail <<~EOM  if Gem::Version.new(Sidekiq::Pro::VERSION).segments[0] != Sidekiq::MAJOR

    Sidekiq Pro #{Sidekiq::Pro::VERSION} does not work with Sidekiq #{Sidekiq::VERSION}.
    Starting with Sidekiq 7, major versions are synchronized so Sidekiq Pro 7 works with Sidekiq 7.
    Use `bundle up sidekiq-pro` to upgrade.

  EOM
rescue LoadError
end

require "sidekiq/config"
require "sidekiq/logger"
require "sidekiq/client"
require "sidekiq/transaction_aware_client"
require "sidekiq/job"
require "sidekiq/iterable_job"
require "sidekiq/worker_compatibility_alias"
require "sidekiq/redis_client_adapter"

require "json"

module Sidekiq
  NAME = "Sidekiq"
  LICENSE = "See LICENSE and the LGPL-3.0 for licensing details."

  def self.❨╯°□°❩╯︵┻━┻
    puts "Take a deep breath and count to ten..."
  end

  def self.server?
    defined?(Sidekiq::CLI)
  end

  def self.load_json(string)
    JSON.parse(string)
  end

  def self.dump_json(object)
    JSON.generate(object)
  end

  def self.pro?
    defined?(Sidekiq::Pro)
  end

  def self.ent?
    defined?(Sidekiq::Enterprise)
  end

  def self.redis_pool
    (Thread.current[:sidekiq_capsule] || default_configuration).redis_pool
  end

  def self.redis(&block)
    (Thread.current[:sidekiq_capsule] || default_configuration).redis(&block)
  end

  def self.strict_args!(mode = :raise)
    Sidekiq::Config::DEFAULTS[:on_complex_arguments] = mode
  end

  def self.default_job_options=(hash)
    @default_job_options = default_job_options.merge(hash.transform_keys(&:to_s))
  end

  def self.default_job_options
    @default_job_options ||= {"retry" => true, "queue" => "default"}
  end

  def self.default_configuration
    @config ||= Sidekiq::Config.new
  end

  def self.logger
    default_configuration.logger
  end

  def self.configure_server(&block)
    (@config_blocks ||= []) << block
    yield default_configuration if server?
  end

  def self.freeze!
    @frozen = true
    @config_blocks = nil
  end

  # Creates a Sidekiq::Config instance that is more tuned for embedding
  # within an arbitrary Ruby process. Notably it reduces concurrency by
  # default so there is less contention for CPU time with other threads.
  #
  #   inst = Sidekiq.configure_embed do |config|
  #     config.queues = %w[critical default low]
  #   end
  #   inst.run
  #   sleep 10
  #   inst.stop
  #
  # NB: it is really easy to overload a Ruby process with threads due to the GIL.
  # I do not recommend setting concurrency higher than 2-3.
  #
  # NB: Sidekiq only supports one instance in memory. You will get undefined behavior
  # if you try to embed Sidekiq twice in the same process.
  def self.configure_embed(&block)
    raise "Sidekiq global configuration is frozen, you must create all embedded instances BEFORE calling `run`" if @frozen

    require "sidekiq/embedded"
    cfg = default_configuration
    cfg.concurrency = 2
    @config_blocks&.each { |block| block.call(cfg) }
    yield cfg

    Sidekiq::Embedded.new(cfg)
  end

  def self.configure_client
    yield default_configuration unless server?
  end

  # We are shutting down Sidekiq but what about threads that
  # are working on some long job?  This error is
  # raised in jobs that have not finished within the hard
  # timeout limit.  This is needed to rollback db transactions,
  # otherwise Ruby's Thread#kill will commit.  See #377.
  # DO NOT RESCUE THIS ERROR IN YOUR JOBS
  class Shutdown < Interrupt; end
end

require "sidekiq/rails" if defined?(::Rails::Engine)
