# -*- encoding : utf-8 -*-
require 'spec_helper'

describe 'Tagger' do
  before(:each) do
    @user = User.create
    @taggable = TaggableModel.create(name: 'Bob Jones')
  end



  it 'should have taggings' do
    @user.tag(@taggable, with: 'ruby,scheme', on: :tags)
    expect(@user.owned_taggings.size).to eq(2)
  end

  it 'should have tags' do
    @user.tag(@taggable, with: 'ruby,scheme', on: :tags)
    expect(@user.owned_tags.size).to eq(2)
  end

  it 'should scope objects returned by tagged_with by owners' do
    @taggable2 = TaggableModel.create(name: 'Jim Jones')
    @taggable3 = TaggableModel.create(name: 'Jane Doe')

    @user2 = User.new
    @user.tag(@taggable, with: 'ruby, scheme', on: :tags)
    @user2.tag(@taggable2, with: 'ruby, scheme', on: :tags)
    @user2.tag(@taggable3, with: 'ruby, scheme', on: :tags)

    expect(TaggableModel.tagged_with(%w(ruby scheme), owned_by: @user).count).to eq(1)
    expect(TaggableModel.tagged_with(%w(ruby scheme), owned_by: @user2).count).to eq(2)
  end

  it 'only returns objects tagged by owned_by when any is true' do
    @user2 = User.new
    @taggable2 = TaggableModel.create(name: 'Jim Jones')
    @taggable3 = TaggableModel.create(name: 'Jane Doe')

    @user.tag(@taggable, with: 'ruby', on: :tags)
    @user.tag(@taggable2, with: 'java', on: :tags)
    @user2.tag(@taggable3, with: 'ruby', on: :tags)

    tags = TaggableModel.tagged_with(%w(ruby java), owned_by: @user, any: true)
    expect(tags).to include(@taggable, @taggable2)
    expect(tags.size).to eq(2)
  end

  it 'only returns objects tagged by owned_by when exclude is true' do
    @user2 = User.new
    @taggable2 = TaggableModel.create(name: 'Jim Jones')
    @taggable3 = TaggableModel.create(name: 'Jane Doe')

    @user.tag(@taggable, with: 'ruby', on: :tags)
    @user.tag(@taggable2, with: 'java', on: :tags)
    @user2.tag(@taggable3, with: 'java', on: :tags)

    tags = TaggableModel.tagged_with(%w(ruby), owned_by: @user, exclude: true)
    expect(tags).to eq([@taggable2])
  end

  it 'should not overlap tags from different taggers' do
    @user2 = User.new
    expect {
      @user.tag(@taggable, with: 'ruby, scheme', on: :tags)
      @user2.tag(@taggable, with: 'java, python, lisp, ruby', on: :tags)
    }.to change(ActsAsTaggableOn::Tagging, :count).by(6)

    [@user, @user2, @taggable].each(&:reload)

    expect(@user.owned_tags.map(&:name).sort).to eq(%w(ruby scheme).sort)
    expect(@user2.owned_tags.map(&:name).sort).to eq(%w(java python lisp ruby).sort)

    expect(@taggable.tags_from(@user).sort).to eq(%w(ruby scheme).sort)
    expect(@taggable.tags_from(@user2).sort).to eq(%w(java lisp python ruby).sort)

    expect(@taggable.all_tags_list.sort).to eq(%w(ruby scheme java python lisp).sort)
    expect(@taggable.all_tags_on(:tags).size).to eq(5)
  end

  it 'should not lose tags from different taggers' do
    @user2 = User.create
    @user2.tag(@taggable, with: 'java, python, lisp, ruby', on: :tags)
    @user.tag(@taggable, with: 'ruby, scheme', on: :tags)

    expect {
      @user2.tag(@taggable, with: 'java, python, lisp', on: :tags)
    }.to change(ActsAsTaggableOn::Tagging, :count).by(-1)

    [@user, @user2, @taggable].each(&:reload)

    expect(@taggable.tags_from(@user).sort).to eq(%w(ruby scheme).sort)
    expect(@taggable.tags_from(@user2).sort).to eq(%w(java python lisp).sort)

    expect(@taggable.all_tags_list.sort).to eq(%w(ruby scheme java python lisp).sort)
    expect(@taggable.all_tags_on(:tags).length).to eq(5)
  end

  it 'should not lose tags' do
    @user2 = User.create

    @user.tag(@taggable, with: 'awesome', on: :tags)
    @user2.tag(@taggable, with: 'awesome, epic', on: :tags)

    expect {
      @user2.tag(@taggable, with: 'epic', on: :tags)
    }.to change(ActsAsTaggableOn::Tagging, :count).by(-1)

    @taggable.reload
    expect(@taggable.all_tags_list).to include('awesome')
    expect(@taggable.all_tags_list).to include('epic')
  end

  it 'should not lose tags' do
    @taggable.update(tag_list: 'ruby')
    @user.tag(@taggable, with: 'ruby, scheme', on: :tags)

    [@taggable, @user].each(&:reload)
    expect(@taggable.tag_list).to eq(%w(ruby))
    expect(@taggable.all_tags_list.sort).to eq(%w(ruby scheme).sort)

    expect {
      @taggable.update(tag_list: '')
    }.to change(ActsAsTaggableOn::Tagging, :count).by(-1)

    expect(@taggable.tag_list).to be_empty
    expect(@taggable.all_tags_list.sort).to eq(%w(ruby scheme).sort)
  end

  it 'is tagger' do
    expect(@user.is_tagger?).to be_truthy
  end

  it 'should skip save if skip_save is passed as option' do
    expect(-> {
      @user.tag(@taggable, with: 'epic', on: :tags, skip_save: true)
    }).to_not change(ActsAsTaggableOn::Tagging, :count)
  end

  it 'should change tags order in ordered taggable' do
    @ordered_taggable = OrderedTaggableModel.create name: 'hey!'

    @user.tag @ordered_taggable, with: 'tag, tag1', on: :tags
    expect(@ordered_taggable.reload.tags_from(@user)).to eq(['tag', 'tag1'])

    @user.tag @ordered_taggable, with: 'tag2, tag1', on: :tags
    expect(@ordered_taggable.reload.tags_from(@user)).to eq(['tag2', 'tag1'])

    @user.tag @ordered_taggable, with: 'tag1, tag2', on: :tags
    expect(@ordered_taggable.reload.tags_from(@user)).to eq(['tag1', 'tag2'])
  end

end
