# -*- encoding: utf-8 -*-
# stub: rack-mini-profiler 3.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rack-mini-profiler".freeze
  s.version = "3.2.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/MiniProfiler/rack-mini-profiler/blob/master/CHANGELOG.md", "source_code_uri" => "https://github.com/MiniProfiler/rack-mini-profiler" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sam Saffron".freeze, "Robin Ward".freeze, "Aleks Totic".freeze]
  s.date = "2023-12-06"
  s.description = "Profiling toolkit for Rack applications with Rails integration. Client Side profiling, DB profiling and Server profiling.".freeze
  s.email = "sam.saffron@gmail.com".freeze
  s.extra_rdoc_files = ["README.md".freeze, "CHANGELOG.md".freeze]
  s.files = ["CHANGELOG.md".freeze, "README.md".freeze]
  s.homepage = "https://miniprofiler.com".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.4.10".freeze
  s.summary = "Profiles loading speed for rack applications.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<rack>.freeze, [">= 1.2.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rack-test>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<dalli>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.12.0".freeze])
  s.add_development_dependency(%q<redis>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<sassc>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<stackprof>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<mini_racer>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<nokogiri>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop-discourse>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<listen>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<webpacker>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rails>.freeze, ["~> 6.0".freeze])
  s.add_development_dependency(%q<webmock>.freeze, ["= 3.9.1".freeze])
  s.add_development_dependency(%q<rubyzip>.freeze, [">= 0".freeze])
end
