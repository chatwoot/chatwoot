# -*- encoding: utf-8 -*-
require 'maxminddb'

describe MaxMindDB::Result do
  subject(:result) { described_class.new(raw_result) }
  let(:raw_result) { {
    "city"=>{
      "geoname_id"=>5375480,
      "names"=>{"de"=>"Mountain View", "en"=>"Mountain View", "fr"=>"Mountain View", "ru"=>"Маунтин-Вью", "zh-CN"=>"芒廷维尤"}
    },
    "continent"=>{
      "code"=>"NA",
      "geoname_id"=>6255149,
      "names"=>{"de"=>"Nordamerika", "en"=>"North America", "es"=>"Norteamérica", "fr"=>"Amérique du Nord", "ja"=>"北アメリカ", "pt-BR"=>"América do Norte", "ru"=>"Северная Америка", "zh-CN"=>"北美洲"}
    },
    "country"=>{
      "geoname_id"=>6252001,
      "iso_code"=>"US",
      "names"=>{"de"=>"USA", "en"=>"United States", "es"=>"Estados Unidos", "fr"=>"États-Unis", "ja"=>"アメリカ合衆国", "pt-BR"=>"Estados Unidos", "ru"=>"США", "zh-CN"=>"美国"}
    },
    "location"=>{
      "latitude"=>37.419200000000004,
      "longitude"=>-122.0574,
      "metro_code"=>"807",
      "time_zone"=>"America/Los_Angeles"
    },
    "postal"=>{
      "code"=>"94043"
    },
    "registered_country"=>{
      "geoname_id"=>6252001,
      "iso_code"=>"US",
      "names"=>{"de"=>"USA", "en"=>"United States", "es"=>"Estados Unidos", "fr"=>"États-Unis", "ja"=>"アメリカ合衆国", "pt-BR"=>"Estados Unidos", "ru"=>"США", "zh-CN"=>"美国"}
    },
    "represented_country"=>{
      "geoname_id"=>6252001,
      "iso_code"=>"US",
      "names"=>{"de"=>"USA", "en"=>"United States", "es"=>"Estados Unidos", "fr"=>"États-Unis", "ja"=>"アメリカ合衆国", "pt-BR"=>"Estados Unidos", "ru"=>"США", "zh-CN"=>"美国"}
    },
    "traits"=>{
      "is_satellite_provider"=>true
    },
    "subdivisions"=>[
      {
        "geoname_id"=>5332921,
        "iso_code"=>"CA",
        "names"=>{"de"=>"Kalifornien", "en"=>"California", "es"=>"California", "fr"=>"Californie", "ja"=>"カリフォルニア州", "pt-BR"=>"Califórnia", "ru"=>"Калифорния", "zh-CN"=>"加利福尼亚州"}
      }
    ],
    "connection_type"=>"Dialup"
  } }

  describe '#[]' do
    it 'should return the given key on the raw result' do
      expect(result['city']).to eq(raw_result['city'])
    end
  end

  describe '#to_hash' do
    it 'should be a kind of Hash' do
      expect(result.to_hash).to be_kind_of(Hash)
    end

    it 'should return full raw data' do
      expect(result.to_hash).to eq(raw_result)
    end
  end

  describe '#city' do
    context 'with a result' do
      it 'should be a kind of MaxMindDB::Result::NamedLocation' do
        expect(result.city).to be_kind_of(MaxMindDB::Result::NamedLocation)
      end

      it 'should initialize the location with the city attributes' do
        expect(MaxMindDB::Result::NamedLocation).to receive(:new).with(raw_result['city'])

        result.city
      end
    end

    context "without a result" do
      let(:raw_result) { nil }

      it 'should be a kind of MaxMindDB::Result::NamedLocation' do
        expect(result.city).to be_kind_of(MaxMindDB::Result::NamedLocation)
      end
    end
  end

  describe '#continent' do
    context 'with a result' do
      it 'should be a kind of MaxMindDB::Result::NamedLocation' do
        expect(result.continent).to be_kind_of(MaxMindDB::Result::NamedLocation)
      end

      it 'should initialize the location with the continent attributes' do
        expect(MaxMindDB::Result::NamedLocation).to receive(:new).with(raw_result['continent'])

        result.continent
      end
    end

    context "without a result" do
      let(:raw_result) { nil }

      it 'should be a kind of MaxMindDB::Result::NamedLocation' do
        expect(result.continent).to be_kind_of(MaxMindDB::Result::NamedLocation)
      end
    end
  end

  describe '#country' do
    context 'with a result' do
      it 'should be a kind of MaxMindDB::Result::NamedLocation' do
        expect(result.country).to be_kind_of(MaxMindDB::Result::NamedLocation)
      end

      it 'should initialize the location with the country attributes' do
        expect(MaxMindDB::Result::NamedLocation).to receive(:new).with(raw_result['country'])

        result.country
      end
    end

    context "without a result" do
      let(:raw_result) { nil }

      it 'should be a kind of MaxMindDB::Result::NamedLocation' do
        expect(result.country).to be_kind_of(MaxMindDB::Result::NamedLocation)
      end
    end
  end

  describe '#found?' do
    context 'with a result' do
      it 'should return true' do
        expect(result.found?).to be_truthy
      end
    end

    context 'without a result' do
      let(:raw_result) { nil }

      it 'should return false' do
        expect(result.found?).to be_falsy
      end
    end
  end

  describe '#location' do
    context 'with a result' do
      it 'should return a kind of MaxMindDB::Result::Location' do
        expect(result.location).to be_kind_of(MaxMindDB::Result::Location)
      end

      it 'should initialize the object with the location attributes' do
        expect(MaxMindDB::Result::Location).to receive(:new).with(raw_result['location'])

        result.location
      end
    end

    context "without a result" do
      let(:raw_result) { nil }

      it 'should be a kind of MaxMindDB::Result::Location' do
        expect(result.location).to be_kind_of(MaxMindDB::Result::Location)
      end
    end
  end

  describe '#postal' do
    context 'with a result' do
      it 'should return a kind of MaxMindDB::Result::Postal' do
        expect(result.postal).to be_kind_of(MaxMindDB::Result::Postal)
      end

      it 'should initialize the object with the postal attributes' do
        expect(MaxMindDB::Result::Postal).to receive(:new).with(raw_result['postal'])

        result.postal
      end
    end

    context "without a result" do
      let(:raw_result) { nil }

      it 'should be a kind of MaxMindDB::Result::Postal' do
        expect(result.postal).to be_kind_of(MaxMindDB::Result::Postal)
      end
    end
  end

  describe '#registered_country' do
    context 'with a result' do
      it 'should be a kind of MaxMindDB::Result::NamedLocation' do
        expect(result.registered_country).to be_kind_of(MaxMindDB::Result::NamedLocation)
      end

      it 'should initialize the location with the registered_country attributes' do
        expect(MaxMindDB::Result::NamedLocation).to receive(:new).with(raw_result['registered_country'])

        result.registered_country
      end
    end
  end

  describe '#represented_country' do
    context 'with a result' do
      it 'should be a kind of MaxMindDB::Result::NamedLocation' do
        expect(result.represented_country).to be_kind_of(MaxMindDB::Result::NamedLocation)
      end

      it 'should initialize the location with the represented_country attributes' do
        expect(MaxMindDB::Result::NamedLocation).to receive(:new).with(raw_result['represented_country'])

        result.represented_country
      end
    end
  end

  describe '#subdivisions' do
    context 'with a result' do
      it 'should be a kind of Array' do
        expect(result.subdivisions).to be_kind_of(Array)
      end

      it 'should return as many results as there are subdivisions passed in' do
        expect(result.subdivisions.length).to eq(raw_result['subdivisions'].length)
      end

      it 'should contain only MaxMindDB::Result::NamedLocation' do
        expect(result.subdivisions.all? { |r| r.kind_of?(MaxMindDB::Result::NamedLocation)}).to be_truthy
      end

      it 'should initialize the location with the correct attributes' do
        expect(MaxMindDB::Result::NamedLocation).to receive(:new).with(raw_result['subdivisions'].first)

        result.subdivisions
      end
    end

    context 'without a result' do
      let(:raw_result) { nil }

      it 'should be a kind of Array' do
        expect(result.subdivisions).to be_kind_of(Array)
      end

      it 'should be empty' do
        expect(result.subdivisions).to be_empty
      end
    end
  end

  describe '#traits' do
    context 'with a result' do
      it 'should return a kind of MaxMindDB::Result::Traits' do
        expect(result.traits).to be_kind_of(MaxMindDB::Result::Traits)
      end

      it 'should initialize the object with the traits attributes' do
        expect(MaxMindDB::Result::Traits).to receive(:new).with(raw_result['traits'])

        result.traits
      end
    end

    context "without a result" do
      let(:raw_result) { nil }

      it 'should be a kind of MaxMindDB::Result::Traits' do
        expect(result.traits).to be_kind_of(MaxMindDB::Result::Traits)
      end
    end
  end

  describe '#connection_type' do
    context 'with a result' do
      it 'should return a String representation of connection type' do
        expect(result.connection_type).to eq("Dialup")
      end
    end

    context "without a result" do
      let(:raw_result) { nil }

      it 'should be nil' do
        expect(result.connection_type).to be_nil
      end
    end
  end
end
