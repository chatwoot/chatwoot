# frozen_string_literal: true

require 'logger'

ENV["ARE_DB"] = "trilogy"

if ENV['AR_VERSION'].to_f <= 7.0
  require "activerecord-trilogy-adapter"
  require "trilogy_adapter/connection"
  ActiveRecord::Base.extend TrilogyAdapter::Connection
end
