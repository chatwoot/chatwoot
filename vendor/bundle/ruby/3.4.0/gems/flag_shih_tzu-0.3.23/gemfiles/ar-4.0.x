source "http://rubygems.org"

gemspec :path => ".."

gem "activerecord", "~> 4.0.0"
gem "sqlite3", "~> 1.3", platforms: [:ruby]
gem "activerecord-jdbcsqlite3-adapter", "~> 1.3.23", platforms: [:jruby]
gem "activerecord-mysql2-adapter", platforms: [:ruby]
gem "activerecord-jdbcmysql-adapter", "~> 1.3.23", platforms: [:jruby]
gem "pg", platforms: [:ruby_18]
gem "activerecord-jdbcpostgresql-adapter", "~> 1.3.23", platforms: [:jruby]

gem "rake", "~> 11"
gem "reek", "~> 3", platforms: [:mri]
gem "roodi", "~> 5", platforms: [:mri]
gem "coveralls", platforms: [:mri_20, :mri_21, :mri_22, :mri_23, :mri_24, :mri_25]
