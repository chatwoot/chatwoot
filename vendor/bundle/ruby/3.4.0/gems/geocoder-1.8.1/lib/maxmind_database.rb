require 'csv'
require 'net/http'

module Geocoder
  module MaxmindDatabase
    extend self

    def download(package, dir = "tmp")
      filepath = File.expand_path(File.join(dir, archive_filename(package)))
      open(filepath, 'wb') do |file|
        uri = URI.parse(archive_url(package))
        Net::HTTP.start(uri.host, uri.port) do |http|
          http.request_get(uri.path) do |resp|
            # TODO: show progress
            resp.read_body do |segment|
              file.write(segment)
            end
          end
        end
      end
    end

    def insert(package, dir = "tmp")
      data_files(package, dir).each do |filepath,table|
        print "Resetting table #{table}..."
        ActiveRecord::Base.connection.execute("DELETE FROM #{table}")
        puts "done"
        insert_into_table(table, filepath)
      end
    end

    def archive_filename(package)
      p = archive_url_path(package)
      s = !(pos = p.rindex('/')).nil? && pos + 1 || 0
      p[s..-1]
    end

    private # -------------------------------------------------------------

    def table_columns(table_name)
      {
        maxmind_geolite_city_blocks: %w[start_ip_num end_ip_num loc_id],
        maxmind_geolite_city_location: %w[loc_id country region city postal_code latitude longitude metro_code area_code],
        maxmind_geolite_country: %w[start_ip end_ip start_ip_num end_ip_num country_code country]
      }[table_name.to_sym]
    end

    def insert_into_table(table, filepath)
      start_time = Time.now
      print "Loading data for table #{table}"
      rows = []
      columns = table_columns(table)
      CSV.foreach(filepath, encoding: "ISO-8859-1") do |line|
        # Some files have header rows.
        # skip if starts with "Copyright" or "locId" or "startIpNum"
        next if line.first.match(/[A-z]/)
        rows << line.to_a
        if rows.size == 10000
          insert_rows(table, columns, rows)
          rows = []
          print "."
        end
      end
      insert_rows(table, columns, rows) if rows.size > 0
      puts "done (#{Time.now - start_time} seconds)"
    end

    def insert_rows(table, headers, rows)
      value_strings = rows.map do |row|
        "(" + row.map{ |col| sql_escaped_value(col) }.join(',') + ")"
      end
      q = "INSERT INTO #{table} (#{headers.join(',')}) " +
        "VALUES #{value_strings.join(',')}"
      ActiveRecord::Base.connection.execute(q)
    end

    def sql_escaped_value(value)
      value.to_i.to_s == value ? value :
        ActiveRecord::Base.connection.quote(value)
    end

    def data_files(package, dir = "tmp")
      case package
      when :geolite_city_csv
        # use the last two in case multiple versions exist
        files = Dir.glob(File.join(dir, "GeoLiteCity_*/*.csv"))[-2..-1].sort
        Hash[*files.zip(["maxmind_geolite_city_blocks", "maxmind_geolite_city_location"]).flatten]
      when :geolite_country_csv
        {File.join(dir, "GeoIPCountryWhois.csv") => "maxmind_geolite_country"}
      end
    end

    def archive_url(package)
      base_url + archive_url_path(package)
    end

    def archive_url_path(package)
      {
        geolite_country_csv: "GeoLite2-Country-CSV.zip",
        geolite_city_csv: "GeoLite2-City-CSV.zip",
        geolite_asn_csv: "GeoLite2-ASN-CSV.zip"
      }[package]
    end

    def base_url
      "http://geolite.maxmind.com/download/geoip/database/"
    end
  end
end
