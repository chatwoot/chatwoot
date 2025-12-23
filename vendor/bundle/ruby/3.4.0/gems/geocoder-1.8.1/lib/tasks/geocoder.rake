require "geocoder/models/mongoid"

namespace :geocode do
  desc "Geocode all objects without coordinates."
  task :all => :environment do
    class_name = ENV['CLASS'] || ENV['class']
    sleep_timer = ENV['SLEEP'] || ENV['sleep']
    batch = ENV['BATCH'] || ENV['batch']
    reverse = ENV['REVERSE'] || ENV['reverse']
    limit = ENV['LIMIT'] || ENV['limit']
    raise "Please specify a CLASS (model)" unless class_name
    klass = class_from_string(class_name)
    batch = (batch.to_i unless batch.nil?) || 1000
    orm = (klass < Geocoder::Model::Mongoid) ? 'mongoid' : 'active_record'
    reverse = false unless reverse.to_s.downcase == 'true'

    geocode_record = lambda { |obj|
      reverse ? obj.reverse_geocode : obj.geocode
      obj.save
      sleep(sleep_timer.to_f) unless sleep_timer.nil?
    }

    scope = reverse ? klass.not_reverse_geocoded : klass.not_geocoded
    scope = scope.limit(limit) if limit
    if orm == 'mongoid'
      scope.each do |obj|
        geocode_record.call(obj)
      end
    elsif orm == 'active_record'
      if limit
        scope.each do |obj|
          geocode_record.call(obj)
        end
      else
        scope.find_each(batch_size: batch) do |obj|
          geocode_record.call(obj)
        end
      end
    end

  end
end
##
# Get a class object from the string given in the shell environment.
# Similar to ActiveSupport's +constantize+ method.
#
def class_from_string(class_name)
  parts = class_name.split("::")
  constant = Object
  parts.each do |part|
    constant = constant.const_get(part)
  end
  constant
end
