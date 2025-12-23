source 'https://rubygems.org'

group :development do
  gem 'benchmark' # necessary on ruby-3.5+
  gem 'bigdecimal' # necessary on ruby-3.3+
  gem 'bundler', '>= 1.16', '< 3'
  gem 'fiddle', platforms: %i[mri windows] # necessary on ruby-3.5+
  gem 'rake', '~> 13.0'
  gem 'rake-compiler', '~> 1.1'
  gem 'rake-compiler-dock', '~> 1.9.0'
  gem 'rspec', '~> 3.0'
end

group :doc do
  gem 'kramdown'
  gem 'yard', '~> 0.9'
end

group :type_check do
  if RUBY_VERSION >= "2.6" && %w[ ruby truffleruby ].include?(RUBY_ENGINE)
    gem 'rbs', '~> 3.0'
  end
end
