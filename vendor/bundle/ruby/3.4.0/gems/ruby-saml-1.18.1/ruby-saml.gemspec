$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'onelogin/ruby-saml/version'

Gem::Specification.new do |s|
  s.name = 'ruby-saml'
  s.version = OneLogin::RubySaml::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["SAML Toolkit", "Sixto Martin"]
  s.email = ['contact@iamdigitalservices.com', 'sixto.martin.garcia@gmail.com']
  s.date = Time.now.strftime("%Y-%m-%d")
  s.description = %q{SAML Ruby toolkit. Add SAML support to your Ruby software using this library}
  s.license = 'MIT'
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  s.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.homepage = %q{https://github.com/saml-toolkits/ruby-saml}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.required_ruby_version = '>= 1.8.7'
  s.summary = %q{SAML Ruby Tookit}

  # Because runtime dependencies are determined at build time, we cannot make
  # Nokogiri's version dependent on the Ruby version, even though we would
  # have liked to constrain Ruby 1.8.7 to install only the 1.5.x versions.
  if defined?(JRUBY_VERSION)
    if JRUBY_VERSION < '9.1.7.0'
      s.add_runtime_dependency('nokogiri', '>= 1.8.2', '<= 1.8.5')
      s.add_runtime_dependency('jruby-openssl', '>= 0.9.8')
      s.add_runtime_dependency('json', '< 2.3.0')
    elsif JRUBY_VERSION < '9.2.0.0'
      s.add_runtime_dependency('nokogiri', '>= 1.9.1', '< 1.10.0')
    elsif JRUBY_VERSION < '9.3.2.0'
      s.add_runtime_dependency('nokogiri', '>= 1.11.4')
      s.add_runtime_dependency('rexml')
    else
      s.add_runtime_dependency('nokogiri', '>= 1.13.10')
      s.add_runtime_dependency('rexml')
    end
  elsif RUBY_VERSION < '1.9'
    s.add_runtime_dependency('uuid')
    s.add_runtime_dependency('nokogiri', '<= 1.5.11')
  elsif RUBY_VERSION < '2.1'
    s.add_runtime_dependency('nokogiri', '>= 1.5.10', '<= 1.6.8.1')
    s.add_runtime_dependency('json', '< 2.3.0')
  elsif RUBY_VERSION < '2.3'
    s.add_runtime_dependency('nokogiri', '>= 1.9.1', '< 1.10.0')
  elsif RUBY_VERSION < '2.5'
    s.add_runtime_dependency('nokogiri', '>= 1.10.10', '< 1.11.0')
    s.add_runtime_dependency('rexml')
  elsif RUBY_VERSION < '2.6'
    s.add_runtime_dependency('nokogiri', '>= 1.11.4')
    s.add_runtime_dependency('rexml')
  else
    s.add_runtime_dependency('nokogiri', '>= 1.13.10')
    s.add_runtime_dependency('rexml')
  end

  if RUBY_VERSION >= '3.4.0'
    s.add_runtime_dependency("logger")
    s.add_runtime_dependency("base64")
    s.add_runtime_dependency('mutex_m')
  end

  s.add_development_dependency('simplecov', '<0.22.0')
  if RUBY_VERSION < '2.4.1'
    s.add_development_dependency('simplecov-lcov', '<0.8.0')
  else
    s.add_development_dependency('simplecov-lcov', '>0.7.0')
  end

  s.add_development_dependency('minitest', '~> 5.5', '<5.19.0')
  s.add_development_dependency('mocha',    '~> 0.14')

  if RUBY_VERSION < '2.0'
    s.add_development_dependency('rake',     '~> 10')
  else
    s.add_development_dependency('rake',     '>= 12.3.3')
  end

  s.add_development_dependency('shoulda',  '~> 2.11')
  s.add_development_dependency('systemu',  '~> 2')

  if RUBY_VERSION < '2.1'
    s.add_development_dependency('timecop',  '<= 0.6.0')
  else
    s.add_development_dependency('timecop',  '~> 0.9')
  end

  if defined?(JRUBY_VERSION)
    # All recent versions of JRuby play well with pry
    s.add_development_dependency('pry')
  elsif RUBY_VERSION < '1.9'
    # 1.8.7
    s.add_development_dependency('ruby-debug', '~> 0.10.4')
  elsif RUBY_VERSION < '2.0'
    # 1.9.x
    s.add_development_dependency('debugger-linecache', '~> 1.2.0')
    s.add_development_dependency('debugger', '~> 1.6.4')
  elsif RUBY_VERSION < '2.1'
    # 2.0.x
    s.add_development_dependency('byebug', '~> 2.1.1')
  else
    # 2.1.x, 2.2.x
    s.add_development_dependency('pry-byebug')
  end
end
