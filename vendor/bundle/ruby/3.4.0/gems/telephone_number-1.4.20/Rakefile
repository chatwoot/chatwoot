require 'bundler/gem_tasks'
require 'rake/testtask'
require 'telephone_number'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
  t.warning = false
end

task :default => :test

namespace :data do
  namespace :main do
    task :import  do
      TelephoneNumber::PhoneDataImporter.new(File.expand_path('data/telephone_number_data_file.xml')).import!
    end
  end

  namespace :timezone do
    task :import do
      TelephoneNumber::TimeZoneDataImporter.load_data!
    end
  end

  namespace :geolocation do
    task :import do
      TelephoneNumber::GeoLocationDataImporter.load_data!
    end
  end

  namespace :test do
    task :import  do
      TelephoneNumber::TestDataImporter.import!
    end
  end
end
