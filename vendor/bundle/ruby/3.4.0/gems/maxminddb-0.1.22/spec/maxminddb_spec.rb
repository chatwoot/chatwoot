require 'maxminddb'

describe MaxMindDB do
  [
    ['default file reader', MaxMindDB::DEFAULT_FILE_READER],
    ['low memory file reader', MaxMindDB::LOW_MEMORY_FILE_READER],
  ].each do |file_reader|
    description, reader = file_reader

    describe description do
      let(:city_db) { MaxMindDB.new('spec/cache/GeoLite2-City.mmdb', reader) }
      let(:country_db) { MaxMindDB.new('spec/cache/GeoLite2-Country.mmdb', reader) }
      let(:rec32_db) { MaxMindDB.new('spec/data/32bit_record_data.mmdb', reader) }

      context 'for the ip 74.125.225.224' do
        let(:ip) { '74.125.225.224' }

        it 'returns a MaxMindDB::Result' do
          expect(city_db.lookup(ip)).to be_kind_of(MaxMindDB::Result)
        end

        it 'finds data' do
          expect(city_db.lookup(ip)).to be_found
        end

        it 'returns Mountain View as the English name' do
          expect(city_db.lookup(ip).city.name).to eq('Alameda')
        end

        it 'returns -122.0574 as the longitude' do
          expect(city_db.lookup(ip).location.longitude).to eq(-122.2788)
        end

        it 'returns nil for is_anonymous_proxy' do
          expect(city_db.lookup(ip).traits.is_anonymous_proxy).to eq(nil)
        end

        it 'returns United States as the English country name' do
          expect(country_db.lookup(ip).country.name).to eq('United States')
        end

        it 'returns false for the is_in_european_union' do
          expect(country_db.lookup(ip).country.is_in_european_union).to eq(nil)
        end

        it 'returns US as the country iso code' do
          expect(country_db.lookup(ip).country.iso_code).to eq('US')
        end
        
        it 'returns 74.125.192.0/18 as network' do 
          expect(country_db.lookup(ip).network).to eq('74.125.192.0/18')
        end

        context 'as a Integer' do
          let(:integer_ip) { IPAddr.new(ip).to_i }

          it 'returns a MaxMindDB::Result' do
            expect(city_db.lookup(integer_ip)).to be_kind_of(MaxMindDB::Result)
          end

          it 'returns Mountain View as the English name' do
            expect(city_db.lookup(integer_ip).city.name).to eq('Alameda')
          end

          it 'returns United States as the English country name' do
            expect(country_db.lookup(integer_ip).country.name).to eq('United States')
          end
        end
      end

      context 'for the ip 2001:708:510:8:9a6:442c:f8e0:7133' do
        let(:ip) { '2001:708:510:8:9a6:442c:f8e0:7133' }

        it 'finds data' do
          expect(city_db.lookup(ip)).to be_found
        end

        it 'returns true for the is_in_european_union' do
          expect(country_db.lookup(ip).country.is_in_european_union).to eq(true)
        end

        it 'returns FI as the country iso code' do
          expect(country_db.lookup(ip).country.iso_code).to eq('FI')
        end
        
        it 'returns 2001:708::/32 as network' do 
          expect(country_db.lookup(ip).network).to eq('2001:708::/32')
        end

        context 'as an integer' do
          let(:integer_ip) { IPAddr.new(ip).to_i }

          it 'returns FI as the country iso code' do
            expect(country_db.lookup(integer_ip).country.iso_code).to eq('FI')
          end
        end
      end

      context 'for a Canadian ipv6' do
        let(:ip) { '2607:5300:60:72ba::' }

        it 'finds data' do
          expect(city_db.lookup(ip)).to be_found
        end

        it 'returns true for the is_in_european_union' do
          expect(country_db.lookup(ip).country.is_in_european_union).to be_falsey
        end

        it 'returns CA as the country iso code' do
          expect(country_db.lookup(ip).country.iso_code).to eq('CA')
        end
      end

      context 'for a German IPv6' do
        let(:ip) { '2a01:488:66:1000:2ea3:495e::1' }

        it 'finds data' do
          expect(city_db.lookup(ip)).to be_found
        end

        it 'returns true for the is_in_european_union' do
          expect(country_db.lookup(ip).country.is_in_european_union).to eq(true)
        end

        it 'returns DE as the country iso code' do
          expect(country_db.lookup(ip).country.iso_code).to eq('DE')
        end
      end

      context 'for the ip 127.0.0.1' do
        let(:ip) { '127.0.0.1' }

        it 'returns a MaxMindDB::Result' do
          expect(city_db.lookup(ip)).to be_kind_of(MaxMindDB::Result)
        end

        it "doesn't find data" do
          expect(city_db.lookup(ip)).to_not be_found
        end
      end

      context 'for local ip addresses' do
        let(:ip) { '127.0.0.1' }

        context 'for city_db' do
          before do
            city_db.local_ip_alias = '74.125.225.224'
          end

          it 'returns a MaxMindDB::Result' do
            expect(city_db.lookup(ip)).to be_kind_of(MaxMindDB::Result)
          end

          it 'finds data' do
            expect(city_db.lookup(ip)).to be_found
          end

          it 'returns Mountain View as the English name' do
            expect(city_db.lookup(ip).city.name).to eq('Alameda')
          end

          it 'returns -122.0574 as the longitude' do
            expect(city_db.lookup(ip).location.longitude).to eq(-122.2788)
          end

          it 'returns nil for is_anonymous_proxy' do
            expect(city_db.lookup(ip).traits.is_anonymous_proxy).to eq(nil)
          end
        end

        context 'for country_db' do
          before do
            country_db.local_ip_alias = '74.125.225.224'
          end

          it 'returns United States as the English country name' do
            expect(country_db.lookup(ip).country.name).to eq('United States')
          end

          it 'returns false for the is_in_european_union' do
            expect(country_db.lookup(ip).country.is_in_european_union).to eq(nil)
          end

          it 'returns US as the country iso code' do
            expect(country_db.lookup(ip).country.iso_code).to eq('US')
          end
        end
      end

      context 'for 32bit record data' do
        let(:ip) { '1.0.16.1' }

        it 'finds data' do
          expect(rec32_db.lookup(ip)).to be_found
        end
      end

      context 'test ips' do
        [
          ['185.23.124.1', 'SA'],
          ['178.72.254.1', 'CZ'],
          ['95.153.177.210', 'RU'],
          ['200.148.105.119', 'BR'],
          ['195.59.71.43', 'GB'],
          ['179.175.47.87', 'BR'],
          ['202.67.40.50', 'ID'],
        ].each do |ip, iso|
          it 'returns a MaxMindDB::Result' do
            expect(city_db.lookup(ip)).to be_kind_of(MaxMindDB::Result)
          end

          it "returns #{iso} as the country iso code" do
            expect(country_db.lookup(ip).country.iso_code).to eq(iso)
          end
        end
      end

      context 'test boolean data' do
        let(:ip) { '41.194.0.1' }

        it 'returns true for the is_satellite_provider trait' do
          expect(city_db.lookup(ip).traits.is_satellite_provider).to eq(nil)
        end

        # There are no false booleans in the database that we can test.
        # False values are simply omitted.
      end
    end
  end
end

# vim: et ts=2 sw=2 ff=unix
