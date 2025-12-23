#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'json'
require 'benchmark'
include Benchmark # rubocop:disable Style/MixinUsage

require 'elastic_apm/sql_summarizer'
require 'elastic_apm/sql/signature'

examples =
  JSON
  .parse(File.read('../apm/tests/random_sql_query_set.json'))
  .map { |ex| ex['input'] }

puts "#{'=' * 14} Parsing #{examples.length} examples #{'=' * 14}"

summarizer = ElasticAPM::SqlSummarizer.new

result_old = nil
result_new = nil

benchmark(CAPTION, 7, FORMAT, 'avg/ex:') do |bm|
  old = bm.report('old:') do
    result_old = examples.map { |i| summarizer.summarize(i) }
  end
  new = bm.report('new:') do
    result_new = examples.map { |i| ElasticAPM::Sql::Signature.parse(i) }
  end

  [(new - old) / examples.length]
end

pp(result_old.count { |res| res == 'SQL' })
pp(result_new.count { |res| res =~ /(--|\/\*\*)/ })

## Stackprof

require 'stackprof'

puts 'Running stackprof'
profile = StackProf.run(mode: :wall, interval: 1) do
  examples.each { |i| ElasticAPM::Sql::Signature.parse(i) }
end
puts ''

StackProf::Report.new(profile).print_text
