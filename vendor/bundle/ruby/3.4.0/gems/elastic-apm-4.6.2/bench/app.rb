#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'active_record'
require 'action_controller/railtie'
require 'elastic-apm'
require 'elastic_apm/railtie'

$log = Logger.new('/tmp/bench.log')

ActiveRecord::Base.logger = $log

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: '/tmp/bench.sqlite3')

ActiveRecord::Schema.define do
  create_table :posts, force: true do |t|
    t.string :title
    t.timestamps
  end
end

class Post < ActiveRecord::Base
end

10.times { |i| Post.create! title: "Post #{i}" }

class ApplicationController < ActionController::Base
  def index
    render inline: '<%= Post.pluck(:title).join(", ") %>'
  end

  def favicon
    render nothing: true
  end
end

class App < Rails::Application
  config.secret_key_base = '__secret'
  config.logger = $log
  config.eager_load = false

  config.elastic_apm.disable_send = true
  config.elastic_apm.logger = $log
  config.elastic_apm.log_level = Logger::DEBUG
end

App.initialize!

App.routes.draw do
  get '/favicon.ico', to: 'application#favicon'
  root to: 'application#index'
end
