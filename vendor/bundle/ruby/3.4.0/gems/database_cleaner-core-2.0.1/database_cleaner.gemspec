require_relative "./lib/database_cleaner/version"

Gem::Specification.new do |spec|
  spec.name        = "database_cleaner"
  spec.version     = DatabaseCleaner::VERSION
  spec.authors     = ["Ben Mabey", "Ernesto Tagwerker", "Micah Geisel"]
  spec.email       = ["ernesto@ombulabs.com"]

  spec.summary     = "Strategies for cleaning databases. Can be used to ensure a clean slate for testing."
  spec.description = "Strategies for cleaning databases. Can be used to ensure a clean slate for testing."
  spec.homepage    = "https://github.com/DatabaseCleaner/database_cleaner"
  spec.license     = "MIT"

  spec.metadata["changelog_uri"] = "https://github.com/DatabaseCleaner/database_cleaner/blob/master/History.rdoc"

  spec.files       = ["lib/database_cleaner.rb"]
  spec.require_paths = ["lib"]

  spec.add_dependency "database_cleaner-active_record", "~>2.0.0"
end
