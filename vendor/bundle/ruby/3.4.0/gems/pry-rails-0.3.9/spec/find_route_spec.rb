# encoding: UTF-8

require 'spec_helper'

describe "find-route" do
  before do
    routes = Rails.application.routes
    routes.draw {
      namespace :admin do
        resources :users
        resources :images
      end
    }
    routes.finalize!
  end

  it 'returns the route for a single action' do
    output = mock_pry('find-route Admin::UsersController#show', 'exit-all')
    output.must_match(/show GET/)
    output.wont_match(/index GET/)
  end

  it 'returns all the routes for a controller' do
    output = mock_pry('find-route Admin::UsersController', 'exit-all')
    output.must_match(/index GET/)
    output.must_match(/show GET/)
    output.must_match(/new GET/)
    output.must_match(/edit GET/)
    output.must_match(/update (PATCH|PUT)/)
    output.must_match(/update PUT/)
    output.must_match(/destroy DELETE/)
  end

  it 'returns all routes for controllers under a namespace' do
    output = mock_pry('find-route Admin', 'exit-all')
    output.must_match(/Routes for Admin::UsersController/)
    output.must_match(/Routes for Admin::ImagesController/)
  end

  it 'returns no routes found when controller is not recognized' do
    output = mock_pry('find-route Foo', 'exit-all')
    output.must_match(/No routes found/)
  end
end
