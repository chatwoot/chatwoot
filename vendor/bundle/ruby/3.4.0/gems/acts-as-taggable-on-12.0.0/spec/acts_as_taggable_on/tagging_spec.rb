# -*- encoding : utf-8 -*-
require 'spec_helper'

describe ActsAsTaggableOn::Tagging do
  before(:each) do
    @tagging = ActsAsTaggableOn::Tagging.new
  end

  it 'should not be valid with a invalid tag' do
    @tagging.taggable = TaggableModel.create(name: 'Bob Jones')
    @tagging.tag = ActsAsTaggableOn::Tag.new(name: '')
    @tagging.context = 'tags'

    expect(@tagging).to_not be_valid

    expect(@tagging.errors[:tag_id]).to eq(['can\'t be blank'])
  end

  it 'should not create duplicate taggings' do
    @taggable = TaggableModel.create(name: 'Bob Jones')
    @tag = ActsAsTaggableOn::Tag.create(name: 'awesome')

    expect {
      2.times { ActsAsTaggableOn::Tagging.create(taggable: @taggable, tag: @tag, context: 'tags') }
    }.to change(ActsAsTaggableOn::Tagging, :count).by(1)
  end

  it 'should not delete tags of other records' do
    6.times { TaggableModel.create(name: 'Bob Jones', tag_list: 'very, serious, bug') }
    expect(ActsAsTaggableOn::Tag.count).to eq(3)
    taggable = TaggableModel.first
    taggable.tag_list = 'bug'
    taggable.save

    expect(taggable.tag_list).to eq(['bug'])

    another_taggable = TaggableModel.where('id != ?', taggable.id).sample
    expect(another_taggable.tag_list.sort).to eq(%w(very serious bug).sort)
  end

  it 'should destroy unused tags after tagging destroyed' do
    previous_setting = ActsAsTaggableOn.remove_unused_tags
    ActsAsTaggableOn.remove_unused_tags = true
    ActsAsTaggableOn::Tag.destroy_all
    @taggable = TaggableModel.create(name: 'Bob Jones')
    @taggable.update_attribute :tag_list, 'aaa,bbb,ccc'
    @taggable.update_attribute :tag_list, ''
    expect(ActsAsTaggableOn::Tag.count).to eql(0)
    ActsAsTaggableOn.remove_unused_tags = previous_setting
  end

  it 'should destroy unused tags after tagging destroyed when not using tags_counter' do
    remove_unused_tags_previous_setting = ActsAsTaggableOn.remove_unused_tags
    tags_counter_previous_setting = ActsAsTaggableOn.tags_counter
    ActsAsTaggableOn.remove_unused_tags = true
    ActsAsTaggableOn.tags_counter = false

    ActsAsTaggableOn::Tag.destroy_all
    @taggable = TaggableModel.create(name: 'Bob Jones')
    @taggable.update_attribute :tag_list, 'aaa,bbb,ccc'
    @taggable.update_attribute :tag_list, ''
    expect(ActsAsTaggableOn::Tag.count).to eql(0)

    ActsAsTaggableOn.remove_unused_tags = remove_unused_tags_previous_setting
    ActsAsTaggableOn.tags_counter = tags_counter_previous_setting
  end

  describe 'context scopes' do
    before do
      @tagging_2 = ActsAsTaggableOn::Tagging.new
      @tagging_3 = ActsAsTaggableOn::Tagging.new

      @tagger = User.new
      @tagger_2 = User.new

      @tagging.taggable = TaggableModel.create(name: "Black holes")
      @tagging.tag = ActsAsTaggableOn::Tag.create(name: "Physics")
      @tagging.tagger = @tagger
      @tagging.context = 'Science'
      @tagging.tenant = 'account1'
      @tagging.save

      @tagging_2.taggable = TaggableModel.create(name: "Satellites")
      @tagging_2.tag = ActsAsTaggableOn::Tag.create(name: "Technology")
      @tagging_2.tagger = @tagger_2
      @tagging_2.context = 'Science'
      @tagging_2.tenant = 'account1'
      @tagging_2.save

      @tagging_3.taggable = TaggableModel.create(name: "Satellites")
      @tagging_3.tag = ActsAsTaggableOn::Tag.create(name: "Engineering")
      @tagging_3.tagger = @tagger_2
      @tagging_3.context = 'Astronomy'
      @tagging_3.save

    end

    describe '.owned_by' do
      it "should belong to a specific user" do
        expect(ActsAsTaggableOn::Tagging.owned_by(@tagger).first).to eq(@tagging)
      end
    end

    describe '.by_context' do
      it "should be found by context" do
        expect(ActsAsTaggableOn::Tagging.by_context('Science').length).to eq(2);
      end
    end

    describe '.by_contexts' do
      it "should find taggings by contexts" do
        expect(ActsAsTaggableOn::Tagging.by_contexts(['Science', 'Astronomy']).first).to eq(@tagging);
        expect(ActsAsTaggableOn::Tagging.by_contexts(['Science', 'Astronomy']).second).to eq(@tagging_2);
        expect(ActsAsTaggableOn::Tagging.by_contexts(['Science', 'Astronomy']).third).to eq(@tagging_3);
        expect(ActsAsTaggableOn::Tagging.by_contexts(['Science', 'Astronomy']).length).to eq(3);
      end
    end

    describe '.by_tenant' do
      it "should find taggings by tenant" do
        expect(ActsAsTaggableOn::Tagging.by_tenant('account1').length).to eq(2);
        expect(ActsAsTaggableOn::Tagging.by_tenant('account1').first).to eq(@tagging);
        expect(ActsAsTaggableOn::Tagging.by_tenant('account1').second).to eq(@tagging_2);
      end
    end

    describe '.not_owned' do
      before do
        @tagging_4 = ActsAsTaggableOn::Tagging.new
        @tagging_4.taggable = TaggableModel.create(name: "Gravity")
        @tagging_4.tag = ActsAsTaggableOn::Tag.create(name: "Space")
        @tagging_4.context = "Science"
        @tagging_4.save
      end

      it "should found the taggings that do not have owner" do
        expect(ActsAsTaggableOn::Tagging.all.length).to eq(4)
        expect(ActsAsTaggableOn::Tagging.not_owned.length).to eq(1)
        expect(ActsAsTaggableOn::Tagging.not_owned.first).to eq(@tagging_4)
      end
    end
  end

  describe 'base_class' do
    before do
      class Foo < ActiveRecord::Base; end
    end

    context "default" do
      it "inherits from ActiveRecord::Base" do

        expect(ActsAsTaggableOn::Tagging.ancestors).to include(ActiveRecord::Base)
        expect(ActsAsTaggableOn::Tagging.ancestors).to_not include(Foo)
      end
    end

    context "custom" do
      it "inherits from custom class" do

        ActsAsTaggableOn.base_class = 'Foo'
        hide_const("ActsAsTaggableOn::Tagging")
        load("lib/acts-as-taggable-on/tagging.rb")

        expect(ActsAsTaggableOn::Tagging.ancestors).to include(Foo)
      end
    end
  end

end
