#!/usr/bin/env ruby
# frozen_string_literal: true

ENV['RAILS_ENV'] = 'production'

require 'bundler'
require 'bundler/setup'

require 'benchmark'
include Benchmark
require 'rack/test'

require './bench/app'

def app
  App
end

include Rack::Test::Methods

def perform
  10_000.times do
    get '/'
  end
end

bench = Benchmark.benchmark(CAPTION, 15, FORMAT) do |b|
  perform # warm up

  b.report('with agent:') { perform }

  ElasticAPM.stop
  perform # warm up

  b.report('without agent:') { perform }
end
