# frozen_string_literal: true

require "test_prof/event_prof/minitest"
require "test_prof/factory_doctor/minitest"

module Minitest # :nodoc:
  module TestProf # :nodoc:
    def self.configure_options(options = {})
      options.tap do |opts|
        opts[:event] = ENV["EVENT_PROF"] if ENV["EVENT_PROF"]
        opts[:rank_by] = ENV["EVENT_PROF_RANK"].to_sym if ENV["EVENT_PROF_RANK"]
        opts[:top_count] = ENV["EVENT_PROF_TOP"].to_i if ENV["EVENT_PROF_TOP"]
        opts[:per_example] = true if ENV["EVENT_PROF_EXAMPLES"]
        opts[:fdoc] = true if ENV["FDOC"]
        opts[:sample] = true if ENV["SAMPLE"] || ENV["SAMPLE_GROUPS"]
      end
    end
  end

  def self.plugin_test_prof_options(opts, options)
    opts.on "--event-prof=EVENT", "Collects metrics for specified EVENT" do |event|
      options[:event] = event
    end
    opts.on "--event-prof-rank-by=RANK_BY", "Defines RANK_BY parameter for results" do |rank|
      options[:rank_by] = rank.to_sym
    end
    opts.on "--event-prof-top-count=N", "Limits results with N groups/examples" do |count|
      options[:top_count] = count.to_i
    end
    opts.on "--event-prof-per-example", TrueClass, "Includes examples metrics to results" do |flag|
      options[:per_example] = flag
    end
    opts.on "--factory-doctor", TrueClass, "Enable Factory Doctor for your examples" do |flag|
      options[:fdoc] = flag
    end
  end

  def self.plugin_test_prof_init(options)
    options = TestProf.configure_options(options)

    reporter << TestProf::EventProfReporter.new(options[:io], options) if options[:event]
    reporter << TestProf::FactoryDoctorReporter.new(options[:io], options) if options[:fdoc]

    ::TestProf::MinitestSample.call if options[:sample]
  end
end
