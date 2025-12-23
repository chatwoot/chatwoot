require "bundler/gem_tasks"
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

desc "Downloads maxmind free DBs if required"
task :ensure_maxmind_files do
  unless File.exist?('spec/cache/GeoLite2-City.mmdb')
    sh 'curl http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz -o spec/cache/GeoLite2-City.mmdb.gz'
    sh 'gunzip spec/cache/GeoLite2-City.mmdb.gz'
  end

  unless File.exist?('spec/cache/GeoLite2-Country.mmdb')
    sh 'curl http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.mmdb.gz -o spec/cache/GeoLite2-Country.mmdb.gz'
    sh 'gunzip spec/cache/GeoLite2-Country.mmdb.gz'
  end
end

desc "Downloads maxmind free DBs if required and runs all specs"
task ensure_maxmind_files_and_spec: [:ensure_maxmind_files, :spec]

task default: :ensure_maxmind_files_and_spec
