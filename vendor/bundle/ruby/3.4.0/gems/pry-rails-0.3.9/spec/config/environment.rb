require 'rails'
require 'rails/all'
require 'active_support/core_ext'

require 'pry-rails'

begin
  require 'mongoid'
rescue LoadError # Mongoid doesn't support Rails 3.0
end

# Initialize our test app

class TestApp < Rails::Application
  config.active_support.deprecation = :log
  config.eager_load = false

  config.secret_token = 'a' * 100

  config.root = File.expand_path('../..', __FILE__)
end

TestApp.initialize!

# Create in-memory database

ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define do
  create_table :pokemons do |t|
    t.string :name
    t.binary :caught
    t.string :species
    t.string :abilities
  end

  create_table :hackers do |t|
    t.integer :social_ability
  end

  create_table :beers do |t|
    t.string :name
    t.string :type
    t.integer :rating
    t.integer :ibu
    t.integer :abv
  end
end

# Define models

class Beer < ActiveRecord::Base
  belongs_to :hacker
end

class Hacker < ActiveRecord::Base
  has_many :pokemons
  has_many :beers
end

class Pokemon < ActiveRecord::Base
  belongs_to :hacker
  has_many :beers, :through => :hacker
end

if defined?(Mongoid)
  class Artist
    include Mongoid::Document

    field :name, :type => String
    embeds_one :beer
    embeds_many :instruments
  end

  class Instrument
    include Mongoid::Document

    field :name, :type => String
    embedded_in :artist
  end
end
