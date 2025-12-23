# -*- encoding: utf-8 -*-
require 'maxminddb'

describe MaxMindDB::Result::NamedLocation do
  subject(:result) { described_class.new(raw_result) }

  context "with a result" do
    let(:raw_result) { {
      "geoname_id"=>6252001,
      "iso_code"=>"US",
      "names"=>{"de"=>"USA", "en"=>"United States", "es"=>"Estados Unidos", "fr"=>"États-Unis", "ja"=>"アメリカ合衆国", "pt-BR"=>"Estados Unidos", "ru"=>"США", "zh-CN"=>"美国"}
    } }

    its(:geoname_id) { should eq(6252001) }
    its(:iso_code) { should eq('US') }

    describe "name" do
      it 'should eq "United States"' do
        expect(result.name).to eq('United States')
      end

      context "with locale :ja" do
        it 'should eq "アメリカ合衆国"' do
          expect(result.name(:ja)).to eq('アメリカ合衆国')
        end
      end
    end
  end

  context "without a result" do
    let(:raw_result) { nil }

    its(:geoname_id) { should be_nil }
    its(:iso_code) { should be_nil }
    its(:name) { should be_nil }
  end
end
