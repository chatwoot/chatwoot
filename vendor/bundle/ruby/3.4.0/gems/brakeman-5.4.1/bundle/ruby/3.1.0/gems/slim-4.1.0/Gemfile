source 'https://rubygems.org/'

gemspec

group :test do
  gem 'sinatra'
  gem 'rack-test'
end

group :perf do
  gem 'benchmark-ips'
  gem 'erubis'
  gem 'haml'
end

if ENV['TRAVIS']
  gem 'rails-controller-testing'
end

if  ENV['TEMPLE'] == 'master'
  gem 'temple', :github => 'judofyr/temple'
end

if ENV['TILT']
  if ENV['TILT'] == 'master'
    gem 'tilt', :github => 'rtomayko/tilt'
  else
    gem 'tilt', "= #{ENV['TILT']}"
  end
end

if ENV['RAILS']
  # we need some smarter test logic for the different Rails versions
  if ENV['RAILS'] == 'master'
    gem 'rails', :github => 'rails/rails'
  else
    gem 'rails', "= #{ENV['RAILS']}"
  end

  gem 'slim-rails', require: false
end

gem 'test-unit', '~> 3.3', '>= 3.3.5'
gem 'minitest', '~> 5.14'

if RUBY_ENGINE == 'rbx' && !ENV['TRAVIS']
  gem 'psych'
end

if ENV['SINATRA']
  if ENV['SINATRA'] == 'master'
    gem 'sinatra', :github => 'sinatra/sinatra'
  else
    gem 'sinatra', :tag => "v#{ENV['SINATRA']}"
  end
end

gem 'rake', '~> 13.0', '>= 13.0.1'
gem 'sassc', '~> 2.2', '>= 2.2.1'
gem 'kramdown', '~> 2.1'

if ENV['TASK'] == 'bench'
  gem 'benchmark-ips'
  gem 'erubis'
  gem 'haml'
end

if ENV['CODECLIMATE_REPO_TOKEN']
  gem 'codeclimate-test-reporter'
end
