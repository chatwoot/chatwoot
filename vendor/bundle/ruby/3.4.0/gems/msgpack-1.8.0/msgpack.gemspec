$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require 'msgpack/version'

Gem::Specification.new do |s|
  s.name = "msgpack"
  s.version = MessagePack::VERSION
  s.summary = "MessagePack, a binary-based efficient data interchange format."
  s.description = %q{MessagePack is a binary-based efficient object serialization library. It enables to exchange structured objects between many languages like JSON. But unlike JSON, it is very fast and small.}
  s.authors = ["Sadayuki Furuhashi", "Theo Hultberg", "Satoshi Tagomori"]
  s.email = ["frsyuki@gmail.com", "theo@iconara.net", "tagomoris@gmail.com"]
  s.license = "Apache 2.0"
  s.homepage = "http://msgpack.org/"
  s.require_paths = ["lib"]
  if /java/ =~ RUBY_PLATFORM
    s.files = Dir['lib/**/*.rb', 'lib/**/*.jar', 'LICENSE']
    s.platform = Gem::Platform.new('java')
  else
    s.files = `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features|bench|doclib|msgpack.org.md|Gemfile|Rakefile)|\.(?:git|circleci|rubocop)|appveyor)})
    end
    s.extensions = ["ext/msgpack/extconf.rb"]
  end

  s.required_ruby_version = ">= 2.5"

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rake-compiler', ['>= 1.1.9']
  s.add_development_dependency 'rspec', ['~> 3.3']
  s.add_development_dependency 'ruby_memcheck'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'json'
  s.add_development_dependency 'benchmark-ips', ['~> 2.10.0']

  s.metadata["changelog_uri"] = "https://github.com/msgpack/msgpack-ruby/blob/master/ChangeLog"
end
