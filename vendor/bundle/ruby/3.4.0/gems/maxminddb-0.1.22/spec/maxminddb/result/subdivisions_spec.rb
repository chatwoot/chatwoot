# -*- encoding: utf-8 -*-
require 'maxminddb'

describe MaxMindDB::Result::Subdivisions do
  subject(:subdivisions) { described_class.new(raw_subdivisions) }

  context "with multiple subdivisions" do
    let(:raw_subdivisions) { [{
      "geoname_id"=>5037779,
      "iso_code"=>"MN",
      "names"=>{"en"=>"Minnesota"}
    }, {
      "geoname_id"=>123,
      "iso_code"=>"HP",
      "names"=>{"en"=>"Hennepin"}
    }] }

    it 'should be a kind of Array' do
      expect(subdivisions).to be_kind_of(Array)
    end

    it 'should return as many items as there are subdivisions passed in' do
      expect(subdivisions.length).to eq(raw_subdivisions.length)
    end

    it 'should contain only MaxMindDB::Result::NamedLocation' do
      expect(subdivisions.all? { |r| r.kind_of?(MaxMindDB::Result::NamedLocation)}).to be_truthy
    end

    describe "most_specific" do
      it 'should be a kind of MaxMindDB::Result::NamedLocation' do
        expect(subdivisions.most_specific).to be_kind_of(MaxMindDB::Result::NamedLocation)
      end

      it 'should eq "Hennepin" subdivision' do
        expect(subdivisions.most_specific.name).to eq("Hennepin")
      end
    end
  end

  context "without a result" do
    let(:raw_subdivisions) { nil }

    it 'should be a kind of Array' do
      expect(subdivisions).to be_kind_of(Array)
    end

    it 'should be empty' do
      expect(subdivisions.length).to eq(0)
    end

    describe "most_specific" do
      it 'should be a kind of MaxMindDB::Result::NamedLocation' do
        expect(subdivisions.most_specific).to be_kind_of(MaxMindDB::Result::NamedLocation)
      end

      it 'should be an empty MaxMindDB::Result::NamedLocation' do
        expect(subdivisions.most_specific.code).to eq(nil)
        expect(subdivisions.most_specific.geoname_id).to eq(nil)
        expect(subdivisions.most_specific.iso_code).to eq(nil)
        expect(subdivisions.most_specific.name).to eq(nil)
      end
    end
  end
end
