# -*- encoding : utf-8 -*-
require 'spec_helper'

describe 'Dirty behavior of taggable objects' do
  context 'with un-contexted tags' do
    before(:each) do
      @taggable = TaggableModel.create(tag_list: 'awesome, epic')
    end

    context 'when tag_list changed' do
      before(:each) do
        expect(@taggable.changes).to be_empty
        @taggable.tag_list = 'one'
      end

      it 'should show changes of dirty object' do
        expect(@taggable.changes).to eq({'tag_list' => [['awesome', 'epic'], ['one']]})
      end

      it 'should show changes of freshly initialized dirty object' do
        taggable = TaggableModel.find(@taggable.id)
        taggable.tag_list = 'one'
        expect(taggable.changes).to eq({'tag_list' => [['awesome', 'epic'], ['one']]})
      end

      if Rails.version >= "5.1"
        it 'flags tag_list as changed' do
          expect(@taggable.will_save_change_to_tag_list?).to be_truthy
        end
      end

      it 'preserves original value' do
        expect(@taggable.tag_list_was).to eq(['awesome', 'epic'])
      end

      it 'shows what the change was' do
        expect(@taggable.tag_list_change).to eq([['awesome', 'epic'], ['one']])
      end

      context 'without order' do
        it 'should not mark attribute if order change ' do
          taggable = TaggableModel.create(name: 'Dirty Harry', tag_list: %w(d c b a))
          taggable.tag_list =  %w(a b c d)
          expect(taggable.tag_list_changed?).to be_falsey
        end
      end

      context 'with order' do
        it 'should mark attribute if order change' do
          taggable = OrderedTaggableModel.create(name: 'Clean Harry', tag_list: 'd,c,b,a')
          taggable.save
          taggable.tag_list =  %w(a b c d)
          expect(taggable.tag_list_changed?).to be_truthy
        end
      end
    end

    context 'when tag_list is the same' do
      before(:each) do
        @taggable.tag_list = 'awesome, epic'
      end

      it 'is not flagged as changed' do
        expect(@taggable.tag_list_changed?).to be_falsy
      end

      it 'does not show any changes to the taggable item' do
        expect(@taggable.changes).to be_empty
      end

      context "and using a delimiter different from a ','" do
        before do
          @old_delimiter = ActsAsTaggableOn.delimiter
          ActsAsTaggableOn.delimiter = ';'
        end

        after do
          ActsAsTaggableOn.delimiter = @old_delimiter
        end

        it 'does not show any changes to the taggable item when using array assignments' do
          @taggable.tag_list = %w(awesome epic)
          expect(@taggable.changes).to be_empty
        end
      end
    end
  end

  context 'with context tags' do
    before(:each) do
      @taggable = TaggableModel.create('language_list' => 'awesome, epic')
    end

    context 'when language_list changed' do
      before(:each) do
        expect(@taggable.changes).to be_empty
        @taggable.language_list = 'one'
      end

      it 'should show changes of dirty object' do
        expect(@taggable.changes).to eq({'language_list' => [['awesome', 'epic'], ['one']]})
      end

      it 'flags language_list as changed' do
        expect(@taggable.language_list_changed?).to be_truthy
      end

      it 'preserves original value' do
        expect(@taggable.language_list_was).to eq(['awesome', 'epic'])
      end

      it 'shows what the change was' do
        expect(@taggable.language_list_change).to eq([['awesome', 'epic'], ['one']])
      end
    end

    context 'when language_list is the same' do
      before(:each) do
        @taggable.language_list = 'awesome, epic'
      end

      it 'is not flagged as changed' do
        expect(@taggable.language_list_changed?).to be_falsy
      end

      it 'does not show any changes to the taggable item' do
        expect(@taggable.changes).to be_empty
      end
    end

    context 'when language_list changed by association' do
      let(:tag) { ActsAsTaggableOn::Tag.new(name: 'one') }

      it 'flags language_list as changed' do
        expect(@taggable.changes).to be_empty
        @taggable.languages << tag
        expect(@taggable.language_list_changed?).to be_truthy
      end
    end

  end
end
