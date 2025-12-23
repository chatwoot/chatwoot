source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in spring-watcher-listen.gemspec
gemspec

if ENV["RAILS_VERSION"] == "edge"
  gem "activesupport", github: "rails/rails", branch: "main"
elsif ENV["RAILS_VERSION"]
  gem "activesupport", "~> #{ENV["RAILS_VERSION"]}.0"
end

gem "spring", github: "rails/spring", branch: "main"
