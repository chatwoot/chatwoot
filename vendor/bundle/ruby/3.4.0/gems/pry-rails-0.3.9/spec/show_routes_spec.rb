# encoding: UTF-8

# We can just have a smoke test for this one since it's mostly using built-in
# Rails functionality. Plus the output is a bit different between Rails
# versions, so that's annoying.

require 'spec_helper'

describe "show-routes" do
  it "should print a list of routes" do
    output = mock_pry('show-routes', 'exit-all')

    output.must_match %r{edit_pokemon GET    /pokemon/edit}
  end

  it "should print a list of routes which include grep option" do
    output = mock_pry('show-routes -G edit', 'exit-all')

    output.must_match %r{edit_pokemon GET    /pokemon/edit}
    output.must_match %r{   edit_beer GET    /beer/edit}
  end

  it "should filter list based on multiple grep options" do
    output = mock_pry('show-routes -G edit -G pokemon', 'exit-all')

    output.must_match %r{edit_pokemon GET    /pokemon/edit}
    output.wont_match %r{edit_beer}
  end
end
