#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require_relative '../bootstrap/lib/channel_readiness'

report = Myinvest::ChannelReadiness::Builder.new(ENV).call
$stdout.puts JSON.generate(report)
exit(report['status'] == 'ready' ? 0 : 1)
