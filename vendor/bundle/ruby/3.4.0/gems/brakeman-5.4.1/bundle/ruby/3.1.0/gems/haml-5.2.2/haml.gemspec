($LOAD_PATH << File.expand_path("../lib", __FILE__)).uniq!
require "haml/version"

Gem::Specification.new do |spec|
  spec.name        = 'haml'
  spec.summary     = "An elegant, structured (X)HTML/XML templating engine."
  spec.version     = Haml::VERSION
  spec.authors     = ['Natalie Weizenbaum', 'Hampton Catlin', 'Norman Clarke', 'Akira Matsuda']
  spec.email       = ['haml@googlegroups.com', 'ronnie@dio.jp']

  spec.executables = ['haml']
  spec.files       = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{\Atest/})
  end
  spec.homepage    = 'http://haml.info/'
  spec.license     = "MIT"
  spec.metadata    = {
    "bug_tracker_uri"   => "https://github.com/haml/haml/issues",
    "changelog_uri"     => "https://github.com/haml/haml/blob/main/CHANGELOG.md",
    "documentation_uri" => "http://haml.info/docs.html",
    "homepage_uri"      => "http://haml.info",
    "mailing_list_uri"  => "https://groups.google.com/forum/?fromgroups#!forum/haml",
    "source_code_uri"   => "https://github.com/haml/haml"
  }

  spec.required_ruby_version = '>= 2.0.0'

  spec.add_dependency 'temple', '>= 0.8.0'
  spec.add_dependency 'tilt'

  spec.add_development_dependency 'rails', '>= 4.0.0'
  spec.add_development_dependency 'rbench'
  spec.add_development_dependency 'minitest', '>= 4.0'
  spec.add_development_dependency 'nokogiri'
  spec.add_development_dependency 'simplecov'

  spec.description = <<-END
Haml (HTML Abstraction Markup Language) is a layer on top of HTML or XML that's
designed to express the structure of documents in a non-repetitive, elegant, and
easy way by using indentation rather than closing tags and allowing Ruby to be
embedded with ease. It was originally envisioned as a plugin for Ruby on Rails,
but it can function as a stand-alone templating engine.
END

end
