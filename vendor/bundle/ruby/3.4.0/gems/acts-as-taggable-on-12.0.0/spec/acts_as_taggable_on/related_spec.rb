# -*- encoding : utf-8 -*-
require 'spec_helper'

describe 'Acts As Taggable On' do

  describe 'Related Objects' do

    #TODO, shared example
    it 'should find related objects based on tag names on context' do
      taggable1 = TaggableModel.create!(name: 'Taggable 1',tag_list: 'one, two')
      taggable2 = TaggableModel.create!(name: 'Taggable 2',tag_list: 'three, four')
      taggable3 = TaggableModel.create!(name: 'Taggable 3',tag_list: 'one, four')

      expect(taggable1.find_related_tags).to include(taggable3)
      expect(taggable1.find_related_tags).to_not include(taggable2)
    end

    it 'finds related tags for ordered taggable on' do
      taggable1 = OrderedTaggableModel.create!(name: 'Taggable 1',colour_list: 'one, two')
      taggable2 = OrderedTaggableModel.create!(name: 'Taggable 2',colour_list: 'three, four')
      taggable3 = OrderedTaggableModel.create!(name: 'Taggable 3',colour_list: 'one, four')

      expect(taggable1.find_related_colours).to include(taggable3)
      expect(taggable1.find_related_colours).to_not include(taggable2)
    end

    it 'should find related objects based on tag names on context - non standard id' do
      taggable1 = NonStandardIdTaggableModel.create!(name: 'Taggable 1',tag_list: 'one, two')
      taggable2 = NonStandardIdTaggableModel.create!(name: 'Taggable 2',tag_list: 'three, four')
      taggable3 = NonStandardIdTaggableModel.create!(name: 'Taggable 3',tag_list: 'one, four')

      expect(taggable1.find_related_tags).to include(taggable3)
      expect(taggable1.find_related_tags).to_not include(taggable2)
    end

    it 'should find other related objects based on tag names on context' do
      taggable1 = TaggableModel.create!(name: 'Taggable 1',tag_list: 'one, two')
      taggable2 = OtherTaggableModel.create!(name: 'Taggable 2',tag_list: 'three, four')
      taggable3 = OtherTaggableModel.create!(name: 'Taggable 3',tag_list: 'one, four')

      expect(taggable1.find_related_tags_for(OtherTaggableModel)).to include(taggable3)
      expect(taggable1.find_related_tags_for(OtherTaggableModel)).to_not include(taggable2)
    end

    it 'should find other related objects based on tags only from particular context' do
      taggable1 = TaggableModel.create!(name: 'Taggable 1',tag_list: 'one, two')
      taggable2 = TaggableModel.create!(name: 'Taggable 2',tag_list: 'three, four', skill_list: 'one, two')
      taggable3 = TaggableModel.create!(name: 'Taggable 3',tag_list: 'one, four')

      expect(taggable1.find_related_tags).to include(taggable3)
      expect(taggable1.find_related_tags).to_not include(taggable2)
    end


    shared_examples "a collection" do
      it do
        taggable1 = described_class.create!(name: 'Taggable 1', tag_list: 'one')
        taggable2 = described_class.create!(name: 'Taggable 2', tag_list: 'one, two')

        expect(taggable1.find_related_tags).to include(taggable2)
        expect(taggable1.find_related_tags).to_not include(taggable1)
      end
    end

    # it 'should not include the object itself in the list of related objects' do
    describe TaggableModel do
      it_behaves_like "a collection"
    end

    # it 'should not include the object itself in the list of related objects - non standard id' do
    describe NonStandardIdTaggableModel do
      it_behaves_like "a collection"
    end

    context 'Ignored Tags' do
      let(:taggable1) { TaggableModel.create!(name: 'Taggable 1', tag_list: 'one, two, four') }
      let(:taggable2) { TaggableModel.create!(name: 'Taggable 2', tag_list: 'two, three') }
      let(:taggable3) { TaggableModel.create!(name: 'Taggable 3', tag_list: 'one, three') }

      it 'should not include ignored tags in related search' do
        expect(taggable1.find_related_tags(ignore: 'two')).to_not include(taggable2)
        expect(taggable1.find_related_tags(ignore: 'two')).to include(taggable3)
      end

      it 'should accept array of ignored tags' do
        taggable4 = TaggableModel.create!(name: 'Taggable 4', tag_list: 'four')


        expect(taggable1.find_related_tags(ignore: ['two', 'four'])).to_not include(taggable2)
        expect(taggable1.find_related_tags(ignore: ['two', 'four'])).to_not include(taggable4)
      end

      it 'should accept symbols as ignored tags' do
        expect(taggable1.find_related_tags(ignore: :two)).to_not include(taggable2)
      end
    end

  end
end
