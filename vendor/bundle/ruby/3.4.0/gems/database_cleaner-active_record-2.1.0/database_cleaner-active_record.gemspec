require_relative "./lib/database_cleaner/active_record/version"

Gem::Specification.new do |spec|
  spec.name          = "database_cleaner-active_record"
  spec.version       = DatabaseCleaner::ActiveRecord::VERSION
  spec.authors       = ["Ernesto Tagwerker", "Micah Geisel"]
  spec.email         = ["ernesto@ombulabs.com"]

  spec.summary       = "Strategies for cleaning databases using ActiveRecord. Can be used to ensure a clean state for testing."
  spec.description   = "Strategies for cleaning databases using ActiveRecord. Can be used to ensure a clean state for testing."
  spec.homepage      = "https://github.com/DatabaseCleaner/database_cleaner-active_record"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.add_dependency "database_cleaner-core", "~>2.0.0"
  spec.add_dependency "activerecord", ">= 5.a"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "mysql2"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "sqlite3"
end
