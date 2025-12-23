
Gem::Specification.new do |s|

  s.name = 'fugit'

  s.version = File.read(
    File.expand_path('../lib/fugit.rb', __FILE__)
  ).match(/ VERSION *= *['"]([^'"]+)/)[1]

  s.platform = Gem::Platform::RUBY
  s.authors = [ 'John Mettraux' ]
  s.email = [ 'jmettraux+flor@gmail.com' ]
  s.homepage = 'https://github.com/floraison/fugit'
  s.license = 'MIT'
  s.summary = 'time tools for flor'

  s.description = %{
Time tools for flor and the floraison project. Cron parsing and occurrence computing. Timestamps and more.
  }.strip

  s.metadata = {
    'changelog_uri' => s.homepage + '/blob/master/CHANGELOG.md',
    'documentation_uri' => s.homepage,
    'bug_tracker_uri' => s.homepage + '/issues',
    #'mailing_list_uri' => 'https://groups.google.com/forum/#!forum/floraison',
    'homepage_uri' =>  s.homepage,
    'source_code_uri' => s.homepage,
    #'wiki_uri' => s.homepage + '/wiki',
  }

  #s.files = `git ls-files`.split("\n")
  s.files = Dir[
    'README.{md,txt}',
    'CHANGELOG.{md,txt}', 'CREDITS.{md,txt}', 'LICENSE.{md,txt}',
    #'Makefile',
    'lib/**/*.rb', #'spec/**/*.rb', 'test/**/*.rb',
    "#{s.name}.gemspec",
  ]

  #s.add_runtime_dependency 'tzinfo'
    # this dependency appears in 'et-orbi'

  s.add_runtime_dependency 'raabro', '~> 1.4'
  s.add_runtime_dependency 'et-orbi', '~> 1', '>= 1.2.11'

  s.add_development_dependency 'rspec', '~> 3.8'
  s.add_development_dependency 'chronic', '~> 0.10'

  s.require_path = 'lib'
end

