#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'jmespath'
require 'json'

expression = ARGV[0]
json = JSON.parse(STDIN.read)

$stdout.puts(JSON.dump(JMESPath.search(expression, json)))
