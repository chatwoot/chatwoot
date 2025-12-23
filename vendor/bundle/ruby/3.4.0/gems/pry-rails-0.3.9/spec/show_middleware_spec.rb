# encoding: UTF-8

require 'spec_helper'

describe "show-middleware" do
  it "should print a list of middleware" do
    output = mock_pry('show-middleware', 'exit-all')

    output.must_match %r{^use ActionDispatch::Static$}
    output.must_match %r{^use ActionDispatch::ShowExceptions$}
    output.must_match %r{^run TestApp.routes\Z}
  end
end

