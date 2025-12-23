Gem::Specification.new do |s|
  s.name = 'stackprof'
  s.version = '0.2.25'
  s.homepage = 'http://github.com/tmm1/stackprof'

  s.authors = 'Aman Gupta'
  s.email   = 'aman@tmm1.net'

  s.metadata = {
    'bug_tracker_uri'   => 'https://github.com/tmm1/stackprof/issues',
    'changelog_uri'     => "https://github.com/tmm1/stackprof/blob/v#{s.version}/CHANGELOG.md",
    'documentation_uri' => "https://www.rubydoc.info/gems/stackprof/#{s.version}",
    'source_code_uri'   => "https://github.com/tmm1/stackprof/tree/v#{s.version}"
  }

  s.files = `git ls-files`.split("\n")
  s.extensions = 'ext/stackprof/extconf.rb'

  s.bindir = 'bin'
  s.executables << 'stackprof'
  s.executables << 'stackprof-flamegraph.pl'
  s.executables << 'stackprof-gprof2dot.py'

  s.summary = 'sampling callstack-profiler for ruby 2.2+'
  s.description = 'stackprof is a fast sampling profiler for ruby code, with cpu, wallclock and object allocation samplers.'

  s.required_ruby_version = '>= 2.2'

  s.license = 'MIT'

  s.add_development_dependency 'rake-compiler', '~> 0.9'
  s.add_development_dependency 'mocha', '~> 0.14'
  s.add_development_dependency 'minitest', '~> 5.0'
end
