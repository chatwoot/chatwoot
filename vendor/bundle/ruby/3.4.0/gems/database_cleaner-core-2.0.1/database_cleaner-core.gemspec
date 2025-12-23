require_relative "./lib/database_cleaner/version"

Gem::Specification.new do |spec|
  spec.name        = "database_cleaner-core"
  spec.version     = DatabaseCleaner::VERSION
  spec.authors     = ["Ben Mabey", "Ernesto Tagwerker"]
  spec.email       = ["ernesto@ombulabs.com"]

  spec.summary     = "Strategies for cleaning databases. Can be used to ensure a clean slate for testing."
  spec.description = "Strategies for cleaning databases. Can be used to ensure a clean slate for testing."
  spec.homepage    = "https://github.com/DatabaseCleaner/database_cleaner"
  spec.license     = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features|examples)/})
  end - ["lib/database_cleaner.rb"] # should only exist in database_cleaner gem
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency "listen"
  spec.add_development_dependency "rspec"

  spec.add_development_dependency "cucumber", "~>3.0"
  spec.add_development_dependency "activesupport"
  spec.add_development_dependency "database_cleaner-active_record"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "database_cleaner-redis"
end
