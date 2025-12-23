source "http://rubygems.org"

gemspec :path => ".."

gem "activerecord", "~> 5.0.0"
gem "sqlite3", "~> 1.3", platforms: [:ruby]
gem "activerecord-mysql2-adapter", platforms: [:ruby]

platform :jruby do
  gem 'jdbc-sqlite3',                         github: "jruby/activerecord-jdbc-adapter", branch: '50-stable'
  gem 'jdbc-mysql',                           github: "jruby/activerecord-jdbc-adapter", branch: '50-stable'
  gem 'jdbc-postgres',                        github: "jruby/activerecord-jdbc-adapter", branch: '50-stable'
  gem 'activerecord-jdbc-adapter',            github: "jruby/activerecord-jdbc-adapter", branch: '50-stable'
  gem "activerecord-jdbcsqlite3-adapter",     github: "jruby/activerecord-jdbc-adapter", branch: '50-stable'
  gem "activerecord-jdbcmysql-adapter",       github: "jruby/activerecord-jdbc-adapter", branch: '50-stable'
  gem "activerecord-jdbcpostgresql-adapter",  github: "jruby/activerecord-jdbc-adapter", branch: '50-stable'
end

gem "reek", "~> 3", platforms: [:mri]
gem "roodi", "~> 5", platforms: [:mri]
gem "coveralls", platforms: [:mri_20, :mri_21, :mri_22, :mri_23, :mri_24, :mri_25]
