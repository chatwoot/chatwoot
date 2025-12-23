module TelephoneNumber
  class TimeZoneDataImporter
    def self.load_data!
      master_data = {}
      File.open('data/timezones/map_data.txt', 'rb').each do |row|
        number_prefix, timezone = row.split('|').map(&:strip)
        master_data[number_prefix] = timezone
      end

      File.open('data/timezones/map_data.dat', 'wb') { |file| file << Marshal.dump(master_data) }
    end
  end
end
