# -*- encoding : utf-8 -*-
require 'spec_helper'

describe 'Acts As Taggable On' do

  it "should provide a class method 'taggable?' that is false for untaggable models" do
    expect(UntaggableModel).to_not be_taggable
  end

  describe 'Taggable Method Generation To Preserve Order' do
    before(:each) do
      TaggableModel.tag_types = []
      TaggableModel.preserve_tag_order = false
      TaggableModel.acts_as_ordered_taggable_on(:ordered_tags)
      @taggable = TaggableModel.new(name: 'Bob Jones')
    end

    it "should respond 'true' to preserve_tag_order?" do
      expect(@taggable.class.preserve_tag_order?).to be_truthy
    end
  end

  describe 'Taggable Method Generation' do
    before(:each) do
      TaggableModel.tag_types = []
      TaggableModel.acts_as_taggable_on(:tags, :languages, :skills, :needs, :offerings)
      @taggable = TaggableModel.new(name: 'Bob Jones')
    end

    it "should respond 'true' to taggable?" do
      expect(@taggable.class).to be_taggable
    end

    it 'should create a class attribute for tag types' do
      expect(@taggable.class).to respond_to(:tag_types)
    end

    it 'should create an instance attribute for tag types' do
      expect(@taggable).to respond_to(:tag_types)
    end

    it 'should have all tag types' do
      expect(@taggable.tag_types).to eq([:tags, :languages, :skills, :needs, :offerings])
    end

    it 'should create a class attribute for preserve tag order' do
      expect(@taggable.class).to respond_to(:preserve_tag_order?)
    end

    it 'should create an instance attribute for preserve tag order' do
      expect(@taggable).to respond_to(:preserve_tag_order?)
    end

    it "should respond 'false' to preserve_tag_order?" do
      expect(@taggable.class.preserve_tag_order?).to be_falsy
    end

    it 'should generate an association for each tag type' do
      expect(@taggable).to respond_to(:tags, :skills, :languages)
    end

    it 'should add tagged_with and tag_counts to singleton' do
      expect(TaggableModel).to respond_to(:tagged_with, :tag_counts)
    end

    it 'should generate a tag_list accessor/setter for each tag type' do
      expect(@taggable).to respond_to(:tag_list, :skill_list, :language_list)
      expect(@taggable).to respond_to(:tag_list=, :skill_list=, :language_list=)
    end

    it 'should generate a tag_list accessor, that includes owned tags, for each tag type' do
      expect(@taggable).to respond_to(:all_tags_list, :all_skills_list, :all_languages_list)
    end
  end

  describe 'Matching Contexts' do
    it 'should find objects with tags of matching contexts' do
      taggable1 = TaggableModel.create!(name: 'Taggable 1')
      taggable2 = TaggableModel.create!(name: 'Taggable 2')
      taggable3 = TaggableModel.create!(name: 'Taggable 3')

      taggable1.offering_list = 'one, two'
      taggable1.save!

      taggable2.need_list = 'one, two'
      taggable2.save!

      taggable3.offering_list = 'one, two'
      taggable3.save!

      expect(taggable1.find_matching_contexts(:offerings, :needs)).to include(taggable2)
      expect(taggable1.find_matching_contexts(:offerings, :needs)).to_not include(taggable3)
    end

    it 'should find other related objects with tags of matching contexts' do
      taggable1 = TaggableModel.create!(name: 'Taggable 1')
      taggable2 = OtherTaggableModel.create!(name: 'Taggable 2')
      taggable3 = OtherTaggableModel.create!(name: 'Taggable 3')

      taggable1.offering_list = 'one, two'
      taggable1.save

      taggable2.need_list = 'one, two'
      taggable2.save

      taggable3.offering_list = 'one, two'
      taggable3.save

      expect(taggable1.find_matching_contexts_for(OtherTaggableModel, :offerings, :needs)).to include(taggable2)
      expect(taggable1.find_matching_contexts_for(OtherTaggableModel, :offerings, :needs)).to_not include(taggable3)
    end

    it 'should not include the object itself in the list of related objects with tags of matching contexts' do
      taggable1 = TaggableModel.create!(name: 'Taggable 1')
      taggable2 = TaggableModel.create!(name: 'Taggable 2')

      taggable1.offering_list = 'one, two'
      taggable1.need_list = 'one, two'
      taggable1.save

      taggable2.need_list = 'one, two'
      taggable2.save

      expect(taggable1.find_matching_contexts_for(TaggableModel, :offerings, :needs)).to include(taggable2)
      expect(taggable1.find_matching_contexts_for(TaggableModel, :offerings, :needs)).to_not include(taggable1)
    end

    it 'should ensure joins to multiple taggings maintain their contexts when aliasing' do
      taggable1 = TaggableModel.create!(name: 'Taggable 1')

      taggable1.offering_list = 'one'
      taggable1.need_list = 'two'

      taggable1.save

      column = TaggableModel.connection.quote_column_name("context")
      offer_alias = TaggableModel.connection.quote_table_name(ActsAsTaggableOn.taggings_table)
      need_alias = TaggableModel.connection.quote_table_name("need_taggings_taggable_models_join")

      expect(TaggableModel.joins(:offerings, :needs).to_sql).to include "#{offer_alias}.#{column}"
      expect(TaggableModel.joins(:offerings, :needs).to_sql).to include "#{need_alias}.#{column}"
    end

  end

  describe 'Tagging Contexts' do
    it 'should eliminate duplicate tagging contexts ' do
      TaggableModel.acts_as_taggable_on(:skills, :skills)
      expect(TaggableModel.tag_types.freq[:skills]).to eq(1)
    end

    it 'should not contain embedded/nested arrays' do
      TaggableModel.acts_as_taggable_on([:array], [:array])
      expect(TaggableModel.tag_types.freq[[:array]]).to eq(0)
    end

    it 'should _flatten_ the content of arrays' do
      TaggableModel.acts_as_taggable_on([:array], [:array])
      expect(TaggableModel.tag_types.freq[:array]).to eq(1)
    end

    it 'should not raise an error when passed nil' do
      expect(-> {
        TaggableModel.acts_as_taggable_on
      }).to_not raise_error
    end

    it 'should not raise an error when passed [nil]' do
      expect(-> {
        TaggableModel.acts_as_taggable_on([nil])
      }).to_not raise_error
    end

    it 'should include dynamic contexts in tagging_contexts' do
      taggable = TaggableModel.create!(name: 'Dynamic Taggable')
      taggable.set_tag_list_on :colors, 'tag1, tag2, tag3'
      expect(taggable.tagging_contexts).to eq(%w(tags languages skills needs offerings array colors))
      taggable.save
      taggable = TaggableModel.where(name: 'Dynamic Taggable').first
      expect(taggable.tagging_contexts).to eq(%w(tags languages skills needs offerings array colors))
    end
  end

  context 'when tagging context ends in an "s" when singular (ex. "status", "glass", etc.)' do
    describe 'caching' do
      before  { @taggable = OtherCachedModel.new(name: 'John Smith') }
      subject { @taggable }

      it { should respond_to(:save_cached_tag_list) }
      its(:cached_language_list) { should be_blank }
      its(:cached_status_list)   { should be_blank }
      its(:cached_glass_list)    { should be_blank }

      context 'language taggings cache after update' do
        before  { @taggable.update(language_list: 'ruby, .net') }
        subject { @taggable }

        its(:language_list)        { should == ['ruby', '.net']}
        its(:cached_language_list) { should == 'ruby, .net' }           # passes
        its(:instance_variables)   { should     include(:@language_list) }
      end

      context 'status taggings cache after update' do
        before  { @taggable.update(status_list: 'happy, married') }
        subject { @taggable }

        its(:status_list)        { should     == ['happy', 'married'] }
        its(:cached_status_list) { should     == 'happy, married'     } # fails
        its(:cached_status_list) { should_not == ''                   } # fails, is blank
        its(:instance_variables) { should     include(:@status_list) }
        its(:instance_variables) { should_not include(:@statu_list)  } # fails, note: one "s"

      end

      context 'glass taggings cache after update' do
        before do
          @taggable.update(glass_list: 'rectangle, aviator')
        end

        subject { @taggable }
        its(:glass_list)         { should     == ['rectangle', 'aviator'] }
        its(:cached_glass_list)  { should     == 'rectangle, aviator'     } # fails
        its(:cached_glass_list)  { should_not == ''                       } # fails, is blank
        its(:instance_variables) { should     include(:@glass_list)      }
        its(:instance_variables) { should_not include(:@glas_list)       } # fails, note: one "s"

      end
    end
  end

  describe 'taggings' do
    before(:each) do
      @taggable = TaggableModel.new(name: 'Art Kram')
    end

    it 'should return no taggings' do
      expect(@taggable.taggings).to be_empty
    end
  end

  describe '@@remove_unused_tags' do
    before do
      @taggable = TaggableModel.create(name: 'Bob Jones')
      @tag = ActsAsTaggableOn::Tag.create(name: 'awesome')

      @tagging = ActsAsTaggableOn::Tagging.create(taggable: @taggable, tag: @tag, context: 'tags')
    end

    context 'if set to true' do
      before do
        ActsAsTaggableOn.remove_unused_tags = true
      end

      it 'should remove unused tags after removing taggings' do
        @tagging.destroy
        expect(ActsAsTaggableOn::Tag.find_by_name('awesome')).to be_nil
      end
    end

    context 'if set to false' do
      before do
        ActsAsTaggableOn.remove_unused_tags = false
      end

      it 'should not remove unused tags after removing taggings' do
        @tagging.destroy
        expect(ActsAsTaggableOn::Tag.find_by_name('awesome')).to eq(@tag)
      end
    end
  end

end
