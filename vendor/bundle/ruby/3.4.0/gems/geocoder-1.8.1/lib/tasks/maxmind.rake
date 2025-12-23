require 'maxmind_database'

namespace :geocoder do
  namespace :maxmind do
    namespace :geolite do

      desc "Download and load/refresh MaxMind GeoLite City data"
      task load: [:download, :extract, :insert]

      desc "Download MaxMind GeoLite City data"
      task :download do
        p = MaxmindTask.check_for_package!
        MaxmindTask.download!(p, dir: ENV['DIR'] || "tmp/")
      end

      desc "Extract (unzip) MaxMind GeoLite City data"
      task :extract do
        p = MaxmindTask.check_for_package!
        MaxmindTask.extract!(p, dir: ENV['DIR'] || "tmp/")
      end

      desc "Load/refresh MaxMind GeoLite City data"
      task insert: [:environment] do
        p = MaxmindTask.check_for_package!
        MaxmindTask.insert!(p, dir: ENV['DIR'] || "tmp/")
      end
    end
  end
end

module MaxmindTask
  extend self

  def check_for_package!
    if %w[city country].include?(p = ENV['PACKAGE'])
      return p
    else
      puts "Please specify PACKAGE=city or PACKAGE=country"
      exit
    end
  end

  def download!(package, options = {})
    p = "geolite_#{package}_csv".intern
    Geocoder::MaxmindDatabase.download(p, options[:dir])
  end

  def extract!(package, options = {})
    begin
      require 'zip'
    rescue LoadError
      puts "Please install gem: rubyzip (>= 1.0.0)"
      exit
    end
    require 'fileutils'
    p = "geolite_#{package}_csv".intern
    archive_filename = Geocoder::MaxmindDatabase.archive_filename(p)
    Zip::File.open(File.join(options[:dir], archive_filename)).each do |entry|
      filepath = File.join(options[:dir], entry.name)
      if File.exist? filepath
        warn "File already exists (#{entry.name}), skipping"
      else
        FileUtils.mkdir_p(File.dirname(filepath))
        entry.extract(filepath)
      end
    end
  end

  def insert!(package, options = {})
    p = "geolite_#{package}_csv".intern
    Geocoder::MaxmindDatabase.insert(p, options[:dir])
  end
end
