# frozen_string_literal: true

require 'ruby-prof'
require 'rack/test'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'elastic-apm'

require './bench/app'
include App::Helpers

def perform(app, count: 1000)
  app.start

  transactions = count.times.map do |i|
    ElasticAPM.transaction "Transaction##{i}",
      context: ElasticAPM.build_context(app.mock_env) do
      ElasticAPM.span('Number one') { 'ok 1' }
      ElasticAPM.span('Number two') { 'ok 2' }
      ElasticAPM.span('Number three') { 'ok 3' }
    end
  end

  app.stop
end

def do_bench(transaction_count: 1000, **config)
  with_app(config) do |app|
    profile = RubyProf::Profile.new
    profile.exclude_common_methods!
    profile.start
    perform(app, count: transaction_count)
    profile.stop
    printer = RubyProf::GraphHtmlPrinter.new(profile)
    printer.print(File.open('bench/tmp/out.html', 'w'))
  end
end

do_bench(transaction_count: 10_000)
