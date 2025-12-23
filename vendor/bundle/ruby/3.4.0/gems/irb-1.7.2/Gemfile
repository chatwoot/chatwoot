source "https://rubygems.org"

gemspec

is_unix = RUBY_PLATFORM =~ /(aix|darwin|linux|(net|free|open)bsd|cygwin|solaris|irix|hpux)/i
is_truffleruby = RUBY_DESCRIPTION =~ /truffleruby/

if is_unix && ENV['WITH_VTERM']
  gem "vterm", github: "ruby/vterm-gem"
  gem "yamatanooroti", github: "ruby/yamatanooroti"
end

gem "stackprof" if is_unix && !is_truffleruby

gem "reline", github: "ruby/reline" if ENV["WITH_LATEST_RELINE"] == "true"
gem "rake"
gem "test-unit"
gem "debug", github: "ruby/debug"
