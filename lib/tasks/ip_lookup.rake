require 'rubygems/package'

namespace :ip_lookup do
  task setup: :environment do
    Geocoder::SetupService.new.perform
  end
end
