# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module DependencyDetection
  module_function

  @items = []

  def defer(&block)
    item = Dependent.new
    item.instance_eval(&block)

    if item.name
      seen_names = @items.map { |i| i.name }.compact
      if seen_names.include?(item.name)
        NewRelic::Agent.logger.warn("Refusing to re-register DependencyDetection block with name '#{item.name}'")
        return @items
      end
    end

    @items << item
    return item
  end

  def detect!
    @items.each do |item|
      if item.dependencies_satisfied?
        item.execute
      else
        item.configure_as_unsatisfied unless item.disabled_configured?
      end
    end
  end

  def dependency_by_name(name)
    @items.find { |i| i.name == name }
  end

  class Dependent
    attr_reader :executed
    attr_accessor :name
    attr_writer :config_name
    attr_reader :dependencies
    attr_reader :prepend_conflicts

    def executed!
      @executed = true
    end

    def config_name
      @config_name || @name
    end

    def initialize
      @dependencies = []
      @executes = []
      @prepend_conflicts = []
      @name = nil
      @config_name = nil
    end

    def dependencies_satisfied?
      !executed and check_dependencies
    end

    def configure_as_unsatisfied
      NewRelic::Agent.config.instance_variable_get(:@cache)[config_key] = :unsatisfied
    end

    def source_location_for(klass, method_name)
      Object.instance_method(:method).bind(klass.allocate).call(method_name).source_location.to_s
    end

    # Extracts the instrumented library name from the instrumenting module's name
    # Given "NewRelic::Agent::Instrumentation::NetHTTP::Prepend"
    # Will extract "NetHTTP" which is in the 2nd to last spot
    def extract_supportability_name(instrumenting_module)
      instrumenting_module.to_s.split('::')[-2]
    end

    def log_and_instrument(method, instrumenting_module, supportability_name)
      supportability_name ||= extract_supportability_name(instrumenting_module)
      NewRelic::Agent.logger.info("Installing New Relic supported #{supportability_name} instrumentation using #{method}")
      NewRelic::Agent.record_metric("Supportability/Instrumentation/#{supportability_name}/#{method}", 0.0)
      yield
    end

    def prepend_instrument(target_class, instrumenting_module, supportability_name = nil)
      log_and_instrument('Prepend', instrumenting_module, supportability_name) do
        target_class.send(:prepend, instrumenting_module)
      end
    end

    def chain_instrument(instrumenting_module, supportability_name = nil)
      log_and_instrument('MethodChaining', instrumenting_module, supportability_name) do
        instrumenting_module.instrument!
      end
    end

    def chain_instrument_target(target, instrumenting_module, supportability_name = nil)
      NewRelic::Agent.logger.info("Installing deferred #{target} instrumentation")
      log_and_instrument('MethodChaining', instrumenting_module, supportability_name) do
        instrumenting_module.instrument!(target)
      end
    end

    def execute
      @executes.each do |x|
        begin
          x.call
        rescue => err
          NewRelic::Agent.logger.error("Error while installing #{self.name} instrumentation:", err)
          break
        end
      end
    ensure
      executed!
    end

    def check_dependencies
      return false unless allowed_by_config? && dependencies

      dependencies.all? do |dep|
        begin
          dep.call
        rescue => err
          NewRelic::Agent.logger.error("Error while detecting #{self.name}:", err)
          false
        end
      end
    end

    def depends_on(&block)
      @dependencies << block if block
    end

    def allowed_by_config?
      !(disabled_configured? || deprecated_disabled_configured?)
    end

    # TODO: MAJOR VERSION
    # will only return true if a disabled key is found and is truthy
    def deprecated_disabled_configured?
      return false if self.name.nil?

      key = "disable_#{self.name}".to_sym
      return false unless ::NewRelic::Agent.config[key] == true

      ::NewRelic::Agent.logger.debug("Not installing #{self.name} instrumentation because of configuration #{key}")
      ::NewRelic::Agent.logger.debug( \
        "[DEPRECATED] configuration #{key} for #{self.name} will be removed in the next major release. " \
        "Use `#{config_key}` with one of `#{VALID_CONFIG_VALUES.map(&:to_s).inspect}`"
      )

      return true
    end

    def config_key
      return nil if self.config_name.nil?

      @config_key ||= "instrumentation.#{self.config_name}".to_sym
    end

    VALID_CONFIG_VALUES = [:auto, :disabled, :prepend, :chain]
    AUTO_CONFIG_VALUE = VALID_CONFIG_VALUES[0]

    VALID_CONFIG_VALUES.each do |value|
      define_method "#{value}_configured?" do
        value == config_value
      end
    end

    # returns only a valid value for instrumentation configuration
    # If user uses "enabled" it's converted to "auto"
    def valid_config_value(retrieved_value)
      VALID_CONFIG_VALUES.include?(retrieved_value) ? retrieved_value : AUTO_CONFIG_VALUE
    end

    # fetches and transform potentially invalid value given to one of the valid config values
    # logs the resolved value during debug mode.
    def fetch_config_value(key)
      valid_value = valid_config_value(::NewRelic::Agent.config[key].to_s.to_sym)
      ::NewRelic::Agent.logger.debug("Using #{valid_value} configuration value for #{self.name} to configure instrumentation")
      return valid_value
    end

    # update any :auto config value to be either :prepend or :chain after auto
    # determination has selected one of those to use
    def update_config_value(use_prepend)
      if config_key && auto_configured?
        NewRelic::Agent.config.instance_variable_get(:@cache)[config_key] = use_prepend ? :prepend : :chain
      end
      use_prepend
    end

    def config_value
      return AUTO_CONFIG_VALUE unless config_key

      fetch_config_value(config_key)
    end

    def named(new_name)
      self.name = new_name
    end

    def configure_with(new_config_name)
      self.config_name = new_config_name
    end

    def executes(&block)
      @executes << block if block
    end

    def conflicts_with_prepend(&block)
      @prepend_conflicts << block if block
    end

    def use_prepend?
      update_config_value(prepend_configured? || (auto_configured? && !prepend_conflicts?))
    end

    def prepend_conflicts?
      @prepend_conflicts.any? do |conflict|
        begin
          conflict.call
        rescue => err
          NewRelic::Agent.logger.error("Error while checking prepend conflicts #{self.name}:", err)
          false # assumes no conflicts exist since `prepend` is preferred method of instrumenting
        end
      end
    end
  end
end
