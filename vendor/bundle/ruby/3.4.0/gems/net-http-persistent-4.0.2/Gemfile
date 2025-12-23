# -*- ruby -*-

source "https://rubygems.org/"

gemspec

gem "rake", "~>13.0"
gem "minitest", "~>5.15", :group => [:development, :test]
gem "rdoc", ">=4.0", "<7", :group => [:development, :test]
gem "rake-manifest", "~>0.2"

gem 'net-http-pipeline', '~> 1.0' if ENV['CI_MATRIX'] == 'pipeline'

# vim: syntax=ruby
