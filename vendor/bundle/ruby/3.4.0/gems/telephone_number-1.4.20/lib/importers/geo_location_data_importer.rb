module TelephoneNumber
  class GeoLocationDataImporter
    def self.load_data!
      Dir.glob("data/geocoding/**/*.txt").each { |file| process_file(file) }
    end

    def self.process_file(file_path)
      master_data = {}
      bin_file_path = "#{File.dirname(file_path)}/#{File.basename(file_path, '.txt')}.dat"

      File.open(file_path, 'r:UTF-8').each do |row|
        next if row.strip !~ /^[0-9]/
        number, location = row.split('|')
        master_data[number.strip] = location.strip
      end

      File.open(bin_file_path, 'wb'){ |file| file << Marshal.dump(master_data) }
    end
  end
end
