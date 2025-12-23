#!/usr/bin/env ruby
# frozen_string_literal: true

require 'stackprof'
require 'rack/test'

require './bench/app'

def app
  App
end

include Rack::Test::Methods

puts 'Running '
profile = StackProf.run(mode: :cpu) do
  10_000.times do
    get '/'
  end
end
puts ''

StackProf::Report.new(profile).print_text
