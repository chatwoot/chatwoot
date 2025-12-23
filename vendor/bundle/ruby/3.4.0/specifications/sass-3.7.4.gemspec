# -*- encoding: utf-8 -*-
# stub: sass 3.7.4 ruby lib

Gem::Specification.new do |s|
  s.name = "sass".freeze
  s.version = "3.7.4".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "source_code_uri" => "https://github.com/sass/ruby-sass" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Natalie Weizenbaum".freeze, "Chris Eppstein".freeze, "Hampton Catlin".freeze]
  s.date = "2019-04-04"
  s.description = "      Ruby Sass is deprecated! See https://sass-lang.com/ruby-sass for details.\n\n      Sass makes CSS fun again. Sass is an extension of CSS, adding\n      nested rules, variables, mixins, selector inheritance, and more.\n      It's translated to well-formatted, standard CSS using the\n      command line tool or a web-framework plugin.\n".freeze
  s.email = "sass-lang@googlegroups.com".freeze
  s.executables = ["sass".freeze, "sass-convert".freeze, "scss".freeze]
  s.files = ["bin/sass".freeze, "bin/sass-convert".freeze, "bin/scss".freeze]
  s.homepage = "https://sass-lang.com/".freeze
  s.licenses = ["MIT".freeze]
  s.post_install_message = "\nRuby Sass has reached end-of-life and should no longer be used.\n\n* If you use Sass as a command-line tool, we recommend using Dart Sass, the new\n  primary implementation: https://sass-lang.com/install\n\n* If you use Sass as a plug-in for a Ruby web framework, we recommend using the\n  sassc gem: https://github.com/sass/sassc-ruby#readme\n\n* For more details, please refer to the Sass blog:\n  https://sass-lang.com/blog/posts/7828841\n\n".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "2.6.14".freeze
  s.summary = "A powerful but elegant CSS compiler that makes CSS fun again.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<sass-listen>.freeze, ["~> 4.0.0".freeze])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.8.7.6".freeze])
  s.add_development_dependency(%q<redcarpet>.freeze, ["~> 3.3".freeze])
  s.add_development_dependency(%q<nokogiri>.freeze, ["~> 1.6.0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, [">= 5".freeze])
end
