source "http://rubygems.org"

gemspec :path => ".."

gem "mime-types", "< 2.0.0", platforms: [:ruby_18]

gem "activerecord", "~> 3.1.0"
gem "sqlite3", "~> 1.3", platforms: [:ruby]
gem "activerecord-jdbcsqlite3-adapter", "~> 1.3.23", platforms: [:jruby]
gem "mysql", platforms: [:ruby_19]
gem "activerecord-mysql2-adapter", platforms: [:ruby_20]
gem "activerecord-jdbcmysql-adapter", "~> 1.3.23", platforms: [:jruby]
gem "pg", platforms: [:ruby_18]
gem "activerecord-jdbcpostgresql-adapter", "~> 1.3.23", platforms: [:jruby]
gem "tins", "~> 1.6.0", platforms: [:ruby_19, :jruby] # released August 13, 2015
gem "term-ansicolor", "~> 1.3.2", platforms: [:ruby_19, :jruby] # released June 23, 2015
gem "unparser", "0.2.4", platforms: [:ruby_19, :ruby_20, :jruby] # released May 30, 2015

gem "rake", "~> 11"
gem "reek", "~> 2.2.1", platforms: [:mri_20, :mri_21, :mri_22, :mri_23, :mri_24, :mri_25]
gem "roodi", "~> 5", platforms: [:mri_20, :mri_21, :mri_22, :mri_23, :mri_24, :mri_25]
gem "coveralls", platforms: [:mri_20, :mri_21, :mri_22, :mri_23, :mri_24, :mri_25]
