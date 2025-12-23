# encoding: UTF-8

require 'spec_helper'

describe "recognize-path" do
  before do
    FooController = Class.new(ActionController::Base)
    BoomsController = Class.new(ActionController::Base)
    routes = Rails.application.routes
    routes.draw {
      root(:to => 'foo#index', :constraints => {:host => 'example.com'})
      resources :booms
    }
    routes.finalize!
  end

  after do
    [:FooController, :BoomsController].each { |const|
      Object.__send__(:remove_const, const)
    }
  end

  it 'fails gracefully if no path is given' do
    output = mock_pry('recognize-path', 'exit-all')
    output.must_equal \
      "Error: The command 'recognize-path' requires an argument.\n"
  end

  it "prints info about controller/action that is bound to the given path" do
    output = mock_pry('recognize-path example.com', 'exit-all')
    output.must_match(/controller.+foo/)
    output.must_match(/action.+index/)
  end

  it "accepts short path" do
    output = mock_pry('recognize-path /booms/1/edit', 'exit-all')
    output.must_match(/action.+edit/)
    output.must_match(/controller.+booms/)
    output.must_match(/id.+1/)
  end

  it "accepts -m switch" do
    output = mock_pry('recognize-path example.com/booms -m post', 'exit-all')
    output.must_match(/controller.+booms/)
    output.must_match(/action.+create/)
  end

  it "doesn't accept unknown methods" do
    output = mock_pry('recognize-path example.com/booms -m posty', 'exit-all')
    output.must_match 'Unknown HTTP method: posty'
  end

  it "doesn't accept unknown routes" do
    output = mock_pry('recognize-path bing/bang/bong', 'exit-all')
    output.must_match 'No route matches "http://bing/bang/bong"'
  end
end
