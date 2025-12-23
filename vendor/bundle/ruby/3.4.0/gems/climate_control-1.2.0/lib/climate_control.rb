require "climate_control/errors"
require "climate_control/version"
require "monitor"

module ClimateControl
  extend self
  extend Gem::Deprecate

  SEMAPHORE = Monitor.new
  private_constant :SEMAPHORE

  def modify(environment_overrides = {}, &block)
    environment_overrides = environment_overrides.transform_keys(&:to_s)

    SEMAPHORE.synchronize do
      previous = ENV.to_hash

      begin
        copy environment_overrides
      ensure
        middle = ENV.to_hash
      end

      block.call
    ensure
      after = ENV
      (previous.keys | middle.keys | after.keys).each do |key|
        if previous[key] != after[key] && middle[key] == after[key]
          ENV[key] = previous[key]
        end
      end
    end
  end

  def unsafe_modify(environment_overrides = {}, &block)
    environment_overrides = environment_overrides.transform_keys(&:to_s)

    previous = ENV.to_hash

    begin
      copy environment_overrides
    ensure
      middle = ENV.to_hash
    end

    block.call
  ensure
    after = ENV
    (previous.keys | middle.keys | after.keys).each do |key|
      if previous[key] != after[key] && middle[key] == after[key]
        ENV[key] = previous[key]
      end
    end
  end

  def env
    ENV
  end

  deprecate :env, "ENV", 2022, 10

  private

  def copy(overrides)
    overrides.each do |key, value|
      ENV[key] = value
    rescue TypeError => e
      raise UnassignableValueError,
        "attempted to assign #{value} to #{key} but failed (#{e.message})"
    end
  end
end
