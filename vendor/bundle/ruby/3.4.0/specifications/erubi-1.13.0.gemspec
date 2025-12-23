# -*- encoding: utf-8 -*-
# stub: erubi 1.13.0 ruby lib

Gem::Specification.new do |s|
  s.name = "erubi".freeze
  s.version = "1.13.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/jeremyevans/erubi/issues", "changelog_uri" => "https://github.com/jeremyevans/erubi/blob/master/CHANGELOG", "mailing_list_uri" => "https://github.com/jeremyevans/erubi/discussions", "source_code_uri" => "https://github.com/jeremyevans/erubi" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jeremy Evans".freeze, "kuwata-lab.com".freeze]
  s.date = "2024-06-13"
  s.description = "Erubi is a ERB template engine for ruby. It is a simplified fork of Erubis".freeze
  s.email = "code@jeremyevans.net".freeze
  s.extra_rdoc_files = ["README.rdoc".freeze, "CHANGELOG".freeze, "MIT-LICENSE".freeze]
  s.files = ["CHANGELOG".freeze, "MIT-LICENSE".freeze, "README.rdoc".freeze]
  s.homepage = "https://github.com/jeremyevans/erubi".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--quiet".freeze, "--line-numbers".freeze, "--inline-source".freeze, "--title".freeze, "Erubi: Small ERB Implementation".freeze, "--main".freeze, "README.rdoc".freeze]
  s.rubygems_version = "3.5.9".freeze
  s.summary = "Small ERB Implementation".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<minitest>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest-global_expectations>.freeze, [">= 0".freeze])
end
