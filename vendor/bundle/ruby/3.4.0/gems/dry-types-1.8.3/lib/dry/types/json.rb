# frozen_string_literal: true

require "dry/types/coercions/json"

module Dry
  module Types
    register("json.nil") do
      self["nominal.nil"].constructor(Coercions::JSON.method(:to_nil))
    end

    register("json.date") do
      self["nominal.date"].constructor(Coercions::JSON.method(:to_date))
    end

    register("json.date_time") do
      self["nominal.date_time"].constructor(Coercions::JSON.method(:to_date_time))
    end

    register("json.time") do
      self["nominal.time"].constructor(Coercions::JSON.method(:to_time))
    end

    register("json.decimal") do
      self["nominal.decimal"].constructor(Coercions::JSON.method(:to_decimal))
    end

    register("json.symbol") do
      self["nominal.symbol"].constructor(Coercions::JSON.method(:to_symbol))
    end

    register("json.array") { self["array"] }

    register("json.hash") { self["hash"] }
  end
end
