# -*- encoding : utf-8 -*-
require 'spec_helper'

describe 'acts_as_tagger' do

  describe 'Tagger Method Generation' do
    before(:each) do
      @tagger = User.new
    end

    it 'should add #is_tagger? query method to the class-side' do
      expect(User).to respond_to(:is_tagger?)
    end

    it 'should return true from the class-side #is_tagger?' do
      expect(User.is_tagger?).to be_truthy
    end

    it 'should return false from the base #is_tagger?' do
      expect(ActiveRecord::Base.is_tagger?).to be_falsy
    end

    it 'should add #is_tagger? query method to the singleton' do
      expect(@tagger).to respond_to(:is_tagger?)
    end

    it 'should add #tag method on the instance-side' do
      expect(@tagger).to respond_to(:tag)
    end

    it 'should generate an association for #owned_taggings and #owned_tags' do
      expect(@tagger).to respond_to(:owned_taggings, :owned_tags)
    end
  end

  describe '#tag' do
    context 'when called with a non-existent tag context' do
      before(:each) do
        @tagger = User.new
        @taggable = TaggableModel.new(name: 'Richard Prior')
      end

      it 'should by default not throw an exception ' do
        expect(@taggable.tag_list_on(:foo)).to be_empty
        expect(-> {
          @tagger.tag(@taggable, with: 'this, and, that', on: :foo)
        }).to_not raise_error
      end

      it 'should by default create the tag context on-the-fly' do
        expect(@taggable.tag_list_on(:here_ond_now)).to be_empty
        @tagger.tag(@taggable, with: 'that', on: :here_ond_now)
        expect(@taggable.tag_list_on(:here_ond_now)).to_not include('that')
        expect(@taggable.all_tags_list_on(:here_ond_now)).to include('that')
      end

      it 'should show all the tag list when both public and owned tags exist' do
        @taggable.tag_list = 'ruby, python'
        @tagger.tag(@taggable, with: 'java, lisp', on: :tags)
        expect(@taggable.all_tags_on(:tags).map(&:name).sort).to eq(%w(ruby python java lisp).sort)
      end

      it 'should not add owned tags to the common list' do
        @taggable.tag_list = 'ruby, python'
        @tagger.tag(@taggable, with: 'java, lisp', on: :tags)
        expect(@taggable.tag_list).to eq(%w(ruby python))
        @tagger.tag(@taggable, with: '', on: :tags)
        expect(@taggable.tag_list).to eq(%w(ruby python))
      end

      it 'should throw an exception when the default is over-ridden' do
        expect(@taggable.tag_list_on(:foo_boo)).to be_empty
        expect {
          @tagger.tag(@taggable, with: 'this, and, that', on: :foo_boo, force: false)
        }.to raise_error(RuntimeError)
      end

      it 'should not create the tag context on-the-fly when the default is over-ridden' do
        expect(@taggable.tag_list_on(:foo_boo)).to be_empty
        @tagger.tag(@taggable, with: 'this, and, that', on: :foo_boo, force: false) rescue
            expect(@taggable.tag_list_on(:foo_boo)).to be_empty
      end
    end

    describe "when called by multiple tagger's" do
      before(:each) do
        @user_x = User.create(name: 'User X')
        @user_y = User.create(name: 'User Y')
        @taggable = TaggableModel.create(name: 'acts_as_taggable_on', tag_list: 'plugin')

        @user_x.tag(@taggable, with: 'ruby, rails', on: :tags)
        @user_y.tag(@taggable, with: 'ruby, plugin', on: :tags)

        @user_y.tag(@taggable, with: '', on: :tags)
        @user_y.tag(@taggable, with: '', on: :tags)
      end

      it 'should delete owned tags' do
        expect(@user_y.owned_tags).to be_empty
      end

      it 'should not delete other taggers tags' do
        expect(@user_x.owned_tags.count).to eq(2)
      end

      it 'should not delete original tags' do
        expect(@taggable.all_tags_list_on(:tags)).to include('plugin')
      end
    end
  end

end
