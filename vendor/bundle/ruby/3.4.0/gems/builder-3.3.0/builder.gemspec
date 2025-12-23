# frozen_string_literal: true
require './lib/builder/version'

Gem::Specification.new do |s|

  #### Basic information.

  s.name = 'builder'
  s.version = Builder::VERSION
  s.summary = "Builders for MarkUp."
  s.description = %{\
Builder provides a number of builder objects that make creating structured data
simple to do.  Currently the following builder objects are supported:

* XML Markup
* XML Events
}

  pkg_files = Dir[
    '[A-Z]*',
    'doc/**/*',
    'lib/**/*.rb',
    'test/**/*.rb',
    'rakelib/**/*'
  ]

  s.files = pkg_files
  s.require_path = 'lib'

  s.test_files = pkg_files.select { |fn| fn =~ /^test\/test/ }

  # s.extra_rdoc_files = rd.rdoc_files.reject { |fn| fn =~ /\.rb$/ }.to_a
  s.rdoc_options <<
    '--title' <<  'Builder -- Easy XML Building' <<
    '--main' << 'README.rdoc' <<
    '--line-numbers'

  s.authors = ["Jim Weirich", "Aaron Patterson"]
  s.email = "aron.patterson@gmail.com"
  s.homepage = "https://github.com/rails/builder"
  s.license = 'MIT'
  s.metadata = {
    "bug_tracker_uri"   => "#{s.homepage}/issues",
    "changelog_uri"     => "#{s.homepage}/blob/master/CHANGES",
    "documentation_uri" => "https://www.rubydoc.info/gems/builder/#{s.version}",
    "homepage_uri"      => s.homepage,
    "source_code_uri"   => "#{s.homepage}/tree/v#{s.version}"
  }
end
