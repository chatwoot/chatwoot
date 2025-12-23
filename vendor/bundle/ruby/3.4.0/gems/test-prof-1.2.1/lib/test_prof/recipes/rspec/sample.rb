# frozen_string_literal: true

module TestProf
  # Instance variable writer for RSpec::Core::World
  module RSpecWorldSamplePatch
    def filtered_examples=(val)
      @filtered_examples = val
    end
  end
end

if ENV["SAMPLE"]
  RSpec::Core::World.include(TestProf::RSpecWorldSamplePatch)

  RSpec.configure do |config|
    config.before(:suite) do
      filtered_examples = RSpec.world.filtered_examples.values.flatten
      random = Random.new(RSpec.configuration.seed)
      sample = filtered_examples.sample(ENV["SAMPLE"].to_i, random: random)
      RSpec.world.filtered_examples = Hash.new do |hash, group|
        hash[group] = group.examples & sample
      end
    end
  end
end

if ENV["SAMPLE_GROUPS"]
  RSpec::Core::World.include(TestProf::RSpecWorldSamplePatch)

  RSpec.configure do |config|
    config.before(:suite) do
      filtered_groups = RSpec.world.filtered_examples.reject do |_group, examples|
        examples.empty?
      end.keys
      random = Random.new(RSpec.configuration.seed)
      sample = filtered_groups.sample(ENV["SAMPLE_GROUPS"].to_i, random: random)
      RSpec.world.filtered_examples = Hash.new do |hash, group|
        hash[group] = sample.include?(group) ? group.examples : []
      end
    end
  end
end
