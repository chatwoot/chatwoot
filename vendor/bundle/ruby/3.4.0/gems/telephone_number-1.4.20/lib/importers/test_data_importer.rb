module TelephoneNumber
  require 'nokogiri'
  require 'httparty'
  require 'yaml'

  class TestDataImporter
    URL =  "https://libphonenumber.appspot.com/phonenumberparser?number=%s&country=%s".freeze
    COUNTRIES = {
                  AE: %w(971529933171 971553006144 971551000291),
                  AR: %w(299154104587 1143211200),
                  AU: %w(0467703037),
                  BE: %w(32498485960 32477702206 32474095692),
                  BO: %w(59178500348 59178006138 59178006139),
                  BR: %w(011992339376 1123456789 11961234567 55991472683),
                  BY: %w(80152450911 294911911 152450911),
                  CA: %w(16135550119 16135550171 16135550112 16135550194
                         16135550122 16135550131 15146708700 14169158200),
                  CH: %w(41794173875 41795061129 41795820985),
                  CL: %w(961234567 221234567),
                  CN: %w(15694876068 13910503766 15845989469 05523245954 04717158875 03748086894),
                  CO: %w(6012345678 3211234567),
                  CR: %w(22123456 83123456),
                  DE: %w(15222503070),
                  DK: %w(4524453744 4551622172 4542428484),
                  EC: %w(593992441504 593984657155 593984015053),
                  EE: %w(37253629280 37253682997 37254004517),
                  ES: %w(34606217800 34667751353 34646570628),
                  FR: %w(0607114556),
                  GB: %w(448444156790 442079308181 442076139800 442076361000
                         07780991912 442076299400 442072227888),
                  HK: %w(64636251),
                  HU: %w(36709311285 36709311279 36709311206),
                  IE: %w(0863634875),
                  IN: %w(915622231515 912942433300 912912510101 911126779191
                         912224818000 917462223999 912266653366 912266325757
                         914066298585 911242451234 911166566162 911123890606
                         911123583754 5622231515 2942433300 2912510101
                         1126779191 2224818000 7462223999 2266653366
                         2266325757 4066298585 1242451234 1166566162
                         1123890606 1123583754 09176642499),
                  IT: %w(393478258998 393440161350),
                  JP: %w(312345678 9012345678),
                  KR: %w(821036424812 821053812833 821085894820),
                  MX: %w(4423593227 14423593227),
                  NL: %w(31610958780 31610000852 31611427604),
                  NO: %w(4792272668 4797065876 4792466013),
                  NZ: %w(64212715077 6421577017 64212862111),
                  PE: %w(51994156035 51987527881 51972737259),
                  PH: %w(639285588185 639285588262 639285548190),
                  PL: %w(48665666003 48885882321 48885889958),
                  QA: %w(97470482288 97474798678),
                  RO: %w(40724242563 40727798526 40727735377),
                  SA: %w(966503891468 966501543349 966500939012),
                  SE: %w(46708922920 46723985268 46761001966),
                  SG: %w(96924755),
                  TR: %w(905497728782 905497728780 905497728781),
                  TT: %w(18687804765 18687804843 18687804752),
                  TW: %w(886905627933 886905627901 886905627925),
                  US: %w(16502530000 14044879000 15123435283 13032450086 16175751300
                         3175083345 13128404100 12485934000 19497941600 14257395600 13103106000
                         16086699600 12125650000 14123456700 14157360000 12068761800
                         12023461100 3175082333, 3502341234, 3502523420, 3502504620, 5292500143,
                         5292520412),
                  VE: %w(584149993108 584248407260 584248271518),
                  ZA: %w(27826187617 27823014578 27828840632)
                }.freeze
    def self.import!
      output_hash = {}
      fetch_data(output_hash)
      write_file(output_hash)
      true
    end

    def self.fetch_data(output_hash)
      COUNTRIES.each do |key, value|
        output_hash[key] = {}

        value.each_with_index do |num, counter|
          page = HTTParty.get(format(URL, num, key.to_s))
          parsed_page = Nokogiri::HTML.parse(page)
          body = parsed_page.elements.first.elements.css('body').first
          parsed_data = parse_remote_data(counter, body.elements.css('table')[2])
          output_hash[key].merge!(parsed_data)
        end
      end
      return output_hash
    end

    def self.parse_remote_data(counter, table)
      output = { counter.to_s => {} }
      table.elements.each do |row|
        next if row.elements.one?
        key = case row.elements.css('th').text
              when 'E164 format'
                :e164_formatted
              when 'National format'
                :national_formatted
              when 'International format'
                :international_formatted
              end

        output[counter.to_s][key] = row.elements.css('td').text if key
      end
      return output
    end

    def self.write_file(data)
      File.open('test/valid_numbers.yml', 'w') do |file|
        file.write "# This file is generated automatically by TestDataImporter. \n" \
          "# Any changes made to this file will be overridden next time test data is generated. \n" \
          "# Please edit TestDataImporter if you need to add test cases. \n"

        file.write data.to_yaml
      end
    end
  end
end
