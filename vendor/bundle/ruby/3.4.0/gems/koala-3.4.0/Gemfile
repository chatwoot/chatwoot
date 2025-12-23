source "https://rubygems.org"

group :development do
  gem 'debugger', :platforms => [:mri_19]
  gem 'byebug', :platforms => [:mri_20, :mri_21]
  gem "yard"
end

group :development, :test do
  gem "psych", '< 4.0.0' # safe_load signature not compatible with older rubies
  gem "rake"
  gem "typhoeus" unless defined? JRUBY_VERSION
  gem 'faraday-typhoeus' unless defined? JRUBY_VERSION
end

group :test do
  gem "rspec", "~> 3.0", "< 3.10" # resrict rspec version until https://github.com/rspec/rspec-support/pull/537 gets merged
  gem "vcr", github: 'vcr/vcr', ref: '8ced6c96e01737a418cd270e0382a8c2c6d85f7f' # needs https://github.com/vcr/vcr/pull/907 for ruby 3.1
  gem "webmock"
  gem "simplecov"
end

gem "jruby-openssl" if defined? JRUBY_VERSION

gemspec
