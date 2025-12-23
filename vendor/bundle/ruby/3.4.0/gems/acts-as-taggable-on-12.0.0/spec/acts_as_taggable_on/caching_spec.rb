# -*- encoding : utf-8 -*-
require 'spec_helper'

describe 'Acts As Taggable On' do

  describe 'Caching' do
    before(:each) do
      @taggable = CachedModel.new(name: 'Bob Jones')
      @another_taggable = OtherCachedModel.new(name: 'John Smith')
    end

    it 'should add saving of tag lists and cached tag lists to the instance' do
      expect(@taggable).to respond_to(:save_cached_tag_list)
      expect(@another_taggable).to respond_to(:save_cached_tag_list)

      expect(@taggable).to respond_to(:save_tags)
    end

    it 'should generate a cached column checker for each tag type' do
      expect(CachedModel).to respond_to(:caching_tag_list?)
      expect(OtherCachedModel).to respond_to(:caching_language_list?)
    end

    it 'should not have cached tags' do
      expect(@taggable.cached_tag_list).to be_blank
      expect(@another_taggable.cached_language_list).to be_blank
    end

    it 'should cache tags' do
      @taggable.update(tag_list: 'awesome, epic')
      expect(@taggable.cached_tag_list).to eq('awesome, epic')

      @another_taggable.update(language_list: 'ruby, .net')
      expect(@another_taggable.cached_language_list).to eq('ruby, .net')
    end

    it 'should keep the cache' do
      @taggable.update(tag_list: 'awesome, epic')
      @taggable = CachedModel.find(@taggable.id)
      @taggable.save!
      expect(@taggable.cached_tag_list).to eq('awesome, epic')
    end

    it 'should update the cache' do
      @taggable.update(tag_list: 'awesome, epic')
      @taggable.update(tag_list: 'awesome')
      expect(@taggable.cached_tag_list).to eq('awesome')
    end

    it 'should remove the cache' do
      @taggable.update(tag_list: 'awesome, epic')
      @taggable.update(tag_list: '')
      expect(@taggable.cached_tag_list).to be_blank
    end

    it 'should have a tag list' do
      @taggable.update(tag_list: 'awesome, epic')
      @taggable = CachedModel.find(@taggable.id)
      expect(@taggable.tag_list.sort).to eq(%w(awesome epic).sort)
    end

    it 'should keep the tag list' do
      @taggable.update(tag_list: 'awesome, epic')
      @taggable = CachedModel.find(@taggable.id)
      @taggable.save!
      expect(@taggable.tag_list.sort).to eq(%w(awesome epic).sort)
    end

    it 'should clear the cache on reset_column_information' do
      CachedModel.column_names
      CachedModel.reset_column_information
      expect(CachedModel.instance_variable_get(:@acts_as_taggable_on_cache_columns)).to eql(nil)
    end

    it 'should not override a user-defined columns method' do
      expect(ColumnsOverrideModel.columns.map(&:name)).not_to include('ignored_column')
      ColumnsOverrideModel.acts_as_taggable
      expect(ColumnsOverrideModel.columns.map(&:name)).not_to include('ignored_column')
    end
  end

  describe 'with a custom delimiter' do
    before(:each) do
      @taggable = CachedModel.new(name: 'Bob Jones')
      @another_taggable = OtherCachedModel.new(name: 'John Smith')
      ActsAsTaggableOn.delimiter = ';'
    end

    after(:all) do
      ActsAsTaggableOn.delimiter = ','
    end

    it 'should cache tags with custom delimiter' do
      @taggable.update(tag_list: 'awesome; epic')
      expect(@taggable.tag_list).to eq(['awesome', 'epic'])
      expect(@taggable.cached_tag_list).to eq('awesome; epic')

      @taggable = CachedModel.find_by_name('Bob Jones')
      expect(@taggable.tag_list).to eq(['awesome', 'epic'])
      expect(@taggable.cached_tag_list).to eq('awesome; epic')
    end
  end

  describe 'Cache methods initialization on new models' do
    before(:all) do
      ActiveRecord::Base.connection.execute(
        'INSERT INTO cache_methods_injected_models (cached_tag_list) VALUES (\'ciao\')'
      )
      class CacheMethodsInjectedModel < ActiveRecord::Base
        acts_as_taggable
      end
    end
    after(:all) { Object.send(:remove_const, :CacheMethodsInjectedModel) }

    it 'cached_tag_list_on? get injected correctly' do
      expect do
        CacheMethodsInjectedModel.first.tag_list
      end.not_to raise_error
    end
  end

  describe 'CachingWithArray' do
    pending '#TODO'
  end
end
